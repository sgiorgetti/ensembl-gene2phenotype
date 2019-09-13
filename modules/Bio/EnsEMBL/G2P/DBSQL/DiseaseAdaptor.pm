=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute
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

package Bio::EnsEMBL::G2P::DBSQL::DiseaseAdaptor;

use Bio::EnsEMBL::G2P::Disease;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $disease = shift;
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO disease (
      name,
      mim
    ) VALUES (?, ?)
  });

  $sth->execute(
    $disease->name,
    $disease->mim || undef,
  );

  $sth->finish();
  
  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'disease', 'disease_id');
  $disease->{disease_id} = $dbID;
  $disease->{dbID} = $dbID;
  return $disease;
}

sub update {
  my $self = shift;
  my $disease = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($disease) || !$disease->isa('Bio::EnsEMBL::G2P::Disease')) {
    die ('Bio::EnsEMBL::G2P::Disease arg expected');
  }
  
  my $sth = $dbh->prepare(q{
    UPDATE disease
      SET name = ?,
          mim = ?
      WHERE disease_id = ?
  });
  $sth->execute(
    $disease->name,
    $disease->mim,
    $disease->dbID
  ); 
  $sth->finish();

  return $disease;
}

sub fetch_by_dbID {
  my $self = shift;
  my $disease_id = shift;
  return $self->SUPER::fetch_by_dbID($disease_id);
}

sub fetch_by_name {
  my $self = shift;
  my $name = shift;
  my $constraint = "d.name='$name'";
  my $result = $self->generic_fetch($constraint);
  $result->[0];
}

sub fetch_by_mim {
  my $self = shift;
  my $mim = shift;
  my $constraint = "d.mim=$mim";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_all_by_substring {
  my $self = shift;
  my $substring = shift;
  my $constraint = "d.name LIKE '%$substring%' LIMIT 20";
  return $self->generic_fetch($constraint);
}

sub store_ontology_accessions{
  my ($self, $pheno) = @_;

  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(qq{
    INSERT IGNORE INTO disease_ontology_accession (
      disease_id,
      accession,
      mapped_by_attrib,
      mapping_type
    ) VALUES (?,?,?,?)
  });

  foreach my $link_info (@{$pheno->{_ontology_accessions}} ){
    ## get attrib id for source of link - can this be mandatory?
    my $attrib_id;
    if ($link_info->{mapping_source}){
      $attrib_id = $self->db->get_AttributeAdaptor->attrib_id_for_type_value( 'ontology_mapping', $link_info->{mapping_source});
      warn "Source type " . $link_info->{mapping_source} . " not supported for linking ontology descriptions to accessions\n" unless $attrib_id;
    }

    $sth->execute(
      $pheno->{dbID},
      $link_info->{accession},
      $attrib_id,
      $link_info->{mapping_type}
    );
  }
  $sth->finish;
}

sub _left_join {
  my $self = shift;

  my @lj = ();

  push @lj, (
    [ 'disease_ontology_accession', 'd.disease_id = doa.disease_id' ]
  ) ;

  return @lj;
}

sub _columns {
  my $self = shift;
  return qw(d.disease_id d.name d.mim doa.accession doa.mapped_by_attrib doa.mapping_type);
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['disease', 'd'], ['disease_ontology_accession', 'doa']
  );
  return @tables;
}

=begin
sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($disease_id, $name, $mim);
  $sth->bind_columns(\($disease_id, $name, $mim));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::Disease->new(
      -disease_id => $disease_id,
      -name => $name,
      -mim => $mim,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}
=end
=cut

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my %row;

  $sth->bind_columns( \( @row{ @{$sth->{NAME_lc} } } ));

  ## deal with multiple rows due to multiple phenotype ontology terms
  while ($sth->fetch) {
    $self->_obj_from_row(\%row);
  }

  # Get the created objects from the temporary hash
  my @objs = values %{ $self->{_temp_objs} };
  delete $self->{_temp_objs};
  return \@objs;
}

sub _obj_from_row {
  my ($self, $row) = @_;

  # If the object for this phenotype_id hasn't already been created, do that
  my $obj = $self->{_temp_objs}{$row->{disease_id}};

  unless (defined($obj)) {

    $obj = Bio::EnsEMBL::G2P::Disease->new_fast({
      dbID  => $row->{disease_id},
      name  => $row->{name},
      mim   => $row->{mim},
      adaptor        => $self,
    });

    $self->{_temp_objs}{$row->{disease_id}} = $obj;
  }

  # Add a ontology accession if available
  my $link_source = $self->db->get_AttributeAdaptor->attrib_value_for_id($row->{mapped_by_attrib})
  if $row->{mapped_by_attrib};

  $obj->add_ontology_accession({
    accession      => $row->{accession},
    mapping_source => $link_source,
    mapping_type   => $row->{mapping_type} }) if defined $row->{accession};
}

1;
