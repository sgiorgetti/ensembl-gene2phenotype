=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2020] EMBL-European Bioinformatics Institute
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
     http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=cut
use strict;
use warnings;

package Bio::EnsEMBL::G2P::DBSQL::LocusGenotypeMechanismAdaptor;

use Bio::EnsEMBL::G2P::LocusGenotypeMechanism;

use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $lgm = shift;
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO locus_genotype_mechanism(
      locus_type,
      locus_id,
      genotype_attrib,
      mechanism_attrib     
    ) VALUES (?, ?, ?, ?)
  });


  my $attribute_adaptor = $self->db->get_AttributeAdaptor;

  if ( defined $lgm->{genotype} ) {
    my @genotype_attribs = ();
    foreach my $genotype (split(',', $lgm->{genotype})) {
      my $attrib = $attribute_adaptor->attrib_id_for_value($genotype);
      if (!defined $attrib) {
        warn "Could not get attrib value for genotype $genotype";
        return undef;
      } else {
        push @genotype_attribs, $attrib;
      }
    }
    $lgm->{genotype_attrib} = join(',', sort @genotype_attribs); 
  }

  if ( defined $lgm->{mechanism} ) {
    $lgm->{mechanism_attrib} = $attribute_adaptor->attrib_id_for_type_value('mutation_consequence', $lgm->{mechanism});
    if (!defined $lgm->{mechanism_attrib}) {
      warn "Could not get attrib value for mechanism " . $lgm->{mechanism};
      return undef;
    }
  }
  $sth->execute(
    $lgm->locus_type,
    $lgm->locus_id,
    $lgm->{genotype_attrib},
    $lgm->{mechanism_attrib}
  );

  $sth->finish();
  
  my $dbID = $dbh->last_insert_id(undef, undef, 'locus_genotype_mechanism', 'locus_genotype_mechanism_id'); 
  $lgm->{dbID} = $dbID;

  return $lgm;
}

sub fetch_by_dbID {
  my $self = shift;
  my $locus_genotype_mechanism_id = shift;
  return $self->SUPER::fetch_by_dbID($locus_genotype_mechanism_id);
}

sub fetch_all {
  my $self = shift;
  return $self->generic_fetch();
}

sub fetch_all_by_Disease {
  my $self = shift;
  my $disease = shift;
  my $cols = join ",", $self->_columns();
  my $sth = $self->prepare(qq{
    SELECT DISTINCT $cols
    FROM locus_genotype_mechanism lgm, lgm_panel lgmp, lgm_panel_disease lgmpd, disease d
    WHERE d.disease_id = lgmpd.disease_id
    AND lgmpd.LGM_panel_id = lgmp.LGM_panel_id
    AND lgmp.locus_genotype_mechanism_id = lgm.locus_genotype_mechanism_id 
    AND d.disease_id = ?;
  });
  $sth->execute($disease->dbID);
  return $self->_objs_from_sth($sth);
}

sub fetch_by_locus_id_locus_type_genotype_mechanism {
  my ($self, $locus_id, $locus_type, $genotypes, $mechanism) = @_;

  my $attribute_adaptor = $self->db->get_AttributeAdaptor;
  my @attribs = ();
  foreach my $genotype (split(',', $genotypes)) {
    my $attrib = $attribute_adaptor->attrib_id_for_type_value('allelic_requirement', $genotype);
    if (!$attrib) {
      warn "Could not get genotype attrib id for value ", $genotype;
      return undef;
    }
    push @attribs, $attrib;
  }
  my $genotype_attrib = join(',', @attribs);

  my $mechanism_attrib = $attribute_adaptor->attrib_id_for_type_value('mutation_consequence', $mechanism);
  if (!$mechanism_attrib) {
    warn "Could not get mechanism attrib id for value ", $mechanism, "\n";
    return undef;
  }

  my $constraint = "lgm.locus_type='$locus_type' AND lgm.locus_id=$locus_id AND lgm.genotype_attrib='$genotype_attrib' AND lgm.mechanism_attrib='$mechanism_attrib';";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_all_by_GeneFeature {
  my $self = shift;
  my $gene_feature = shift;
  my $cols = join ",", $self->_columns();
  my @lgms = ();
  my $sth = $self->prepare(qq{
    SELECT DISTINCT $cols
    FROM locus_genotype_mechanism lgm, allele_feature af, transcript_allele ta, gene_feature gf
    WHERE gf.gene_feature_id = ta.gene_feature_id
    AND ta.allele_feature_id = af.allele_feature_id
    AND af.allele_feature_id = lgm.locus_id
    AND lgm.locus_type = 'allele'
    AND gf.gene_feature_id = ?;
  });
  $sth->execute($gene_feature->dbID);
  push @lgms, @{$self->_objs_from_sth($sth)}; 

  $sth = $self->prepare(qq{
    SELECT DISTINCT $cols
    FROM locus_genotype_mechanism lgm, gene_feature gf
    WHERE gf.gene_feature_id = lgm.locus_id
    AND lgm.locus_type = 'gene'
    AND gf.gene_feature_id = ?;
  });
  $sth->execute($gene_feature->dbID);
  push @lgms, @{$self->_objs_from_sth($sth)}; 

  return \@lgms;
}

sub _columns {
  my $self = shift;
  my @cols = (
    'lgm.locus_genotype_mechanism_id',
    'lgm.locus_type',
    'lgm.locus_id',
    'lgm.genotype_attrib',
    'lgm.mechanism_attrib',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['locus_genotype_mechanism', 'lgm'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;
  my ($locus_genotype_mechanism_id, $locus_type, $locus_id, $genotype_attrib, $mechanism_attrib);
  $sth->bind_columns(\($locus_genotype_mechanism_id, $locus_type, $locus_id, $genotype_attrib, $mechanism_attrib));

  my @objs;

  my $attribute_adaptor = $self->db->get_AttributeAdaptor;

  while ($sth->fetch()) {
    my $genotype = undef;
    my $mechanism = undef;

    if ($genotype_attrib) {
      my @ids = split(',', $genotype_attrib);
      my @values = ();
      foreach my $id (@ids) {
        push @values, $attribute_adaptor->attrib_value_for_id($id);
      }
      $genotype = join(',', sort @values);
    }

    if ($mechanism_attrib) {
      $mechanism = $attribute_adaptor->attrib_value_for_id($mechanism_attrib);
    }

    my $obj = Bio::EnsEMBL::G2P::LocusGenotypeMechanism->new(
      -locus_genotype_mechanism_id => $locus_genotype_mechanism_id,
      -locus_type => $locus_type,
      -locus_id => $locus_id,
      -genotype_attrib => $genotype_attrib,
      -genotype => $genotype,
      -mechanism_attrib => $mechanism_attrib,
      -mechanism => $mechanism,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
