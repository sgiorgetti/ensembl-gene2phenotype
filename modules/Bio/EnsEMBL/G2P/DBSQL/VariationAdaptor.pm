=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

package Bio::EnsEMBL::G2P::DBSQL::VariationAdaptor;

use Bio::EnsEMBL::G2P::Disease;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $variation = shift;  
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO variation (
      genomic_feature_id,
      disease_id,
      publication_id,
      mutation,
      consequence
    ) VALUES (?,?,?,?,?)
  });
  $sth->execute(
    $variation->genomic_feature_id,
    $variation->disease_id,
    $variation->publication_id || undef,
    $variation->mutation || undef,
    $variation->consequence || undef
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'variation', 'variation_id');
  $variation->{variation_id} = $dbID;

  # insert synonyms
  $sth = $dbh->prepare(q{
    INSERT INTO variation_synonym (
      variation_id,
      name,
      source
    ) VALUES (?,?,?)
  });

  my $synonyms = $variation->{synonyms};
  foreach my $source (keys %$synonyms) {
    foreach my $name (keys %{$synonyms->{$source}}) {
      $sth->execute(
        $dbID,
        $name,
        $source
      );
    }  
  } 
  $sth->finish();
  return $variation;
}

# disease_name -> genomic_feature -> variation
sub fetch_all_by_genomic_feature_id_disease_id {
  my $self = shift;
  my $genomic_feature_id = shift;
  my $disease_id = shift;
  my $constraint = "v.genomic_feature_id=$genomic_feature_id AND v.disease_id=$disease_id";
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_Disease_order_by_genomic_feature_id {
  my $self = shift;
  my $disease = shift;
  my $disease_id = $disease->dbID;
  my $constraint = "v.disease_id=$disease_id";
  my $variations = $self->generic_fetch($constraint);
  my $genomic_features = {};
  foreach my $variation (@$variations) {
    my $genomic_feature_id = $variation->genomic_feature_id;
    push @{$genomic_features->{$genomic_feature_id}}, $variation;
  }
  return $genomic_features;
}

sub fetch_all_by_GenomicFeature_order_by_disease_id {
  my $self = shift;
  my $genomic_feature = shift;
  my $genomic_feature_id = $genomic_feature->dbID;
  my $constraint = "v.genomic_feature_id=$genomic_feature_id";
  my $variations = $self->generic_fetch($constraint);
  my $diseases = {};
  foreach my $variation (@$variations) {
    my $disease_id = $variation->disease_id;
    push @{$diseases->{$disease_id}}, $variation;
  }
  return $diseases;
}

sub fetch_all_synonyms_order_by_source_by_variation_id {
  my $self = shift;
  my $variation_id = shift;
  my $variation_synonyms = {};
  my $query = "SELECT name, source FROM variation_synonym WHERE variation_id=$variation_id";
  my $dbh = $self->dbc->db_handle;
  my $sth = $dbh->prepare($query);
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my $name = $row->[0];
    my $source = $row->[1];
    push @{$variation_synonyms->{$source}}, $name;
  }
  return $variation_synonyms;
}

sub fetch_all_by_genomic_feature_id {
  my $self = shift;
  my $genomic_feature_id = shift;
  my $constraint = "v.genomic_feature_id=$genomic_feature_id";
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_disease_id {
  my $self = shift;
  my $disease_id = shift;
  my $constraint = "v.disease_id=$disease_id";
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'v.variation_id',
    'v.genomic_feature_id',
    'v.disease_id',
    'v.publication_id',
    'v.mutation',
    'v.consequence'
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['variation', 'v'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($variation_id, $genomic_feature_id, $disease_id, $publication_id, $mutation, $consequence);
  $sth->bind_columns(\($variation_id, $genomic_feature_id, $disease_id, $publication_id, $mutation, $consequence));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::Variation->new(
      -variation_id => $variation_id,
      -genomic_feature_id => $genomic_feature_id,
      -disease_id => $disease_id,
      -publication_id => $publication_id,
      -mutation => $mutation,
      -consequence => $consequence,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
