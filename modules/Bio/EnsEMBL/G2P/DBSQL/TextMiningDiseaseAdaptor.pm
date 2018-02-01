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

package Bio::EnsEMBL::G2P::DBSQL::TextMiningDiseaseAdaptor;

use Bio::EnsEMBL::G2P::TextMiningDisease;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $disease = shift;  
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO text_mining_disease (
      publication_id,
      mesh_id,
      annotated_text,
      source
    ) VALUES (?,?,?,?)
  });
  $sth->execute(
    $disease->publication_id,
    $disease->genomic_feature_id,
    $disease->text_mining_hgvs,
    $disease->ensembl_hgvs,
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'text_mining_disease', 'text_mining_disease_id');
  $disease->{text_mining_disease_id} = $dbID;
  return $disease;
}

sub fetch_all_by_Publication {
  my $self = shift;
  my $publication = shift;
  my $constraint = "tmd.publication_id=" . $publication->dbID;
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'tmd.text_mining_disease_id',
    'tmd.publication_id',
    'tmd.mesh_id',
    'tmd.annotated_text',
    'tmd.source',
    'pm.phenotype_id',
    'm.stable_id as mesh_stable_id',
    'm.name as mesh_name'
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['text_mining_disease', 'tmd'],
    ['mesh', 'm'],
    ['phenotype_mapping', 'pm']
  );
  return @tables;
}

sub _left_join {
  my $self = shift;

  my @left_join = (
    ['mesh', 'tmd.mesh_id = m.mesh_id'],
    ['phenotype_mapping', 'tmd.mesh_id = pm.mesh_id'],
  );
  return @left_join;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;
  my %row;
  $sth->bind_columns( \( @row{ @{$sth->{NAME_lc} } } ));
  while ($sth->fetch) {
    # we don't actually store the returned object because
    # the _obj_from_row method stores them in a temporary
    # hash _temp_objs in $self
    $self->_obj_from_row(\%row);
  }

  # Get the created objects from the temporary hash
  my @objs = values %{ $self->{_temp_objs} };
  delete $self->{_temp_objs};

  # Return the created objects
  return \@objs;
}

sub _obj_from_row {
  my ($self, $row) = @_;
  my $obj = $self->{_temp_objs}{$row->{text_mining_disease_id}};
  unless ( defined $obj ) {
    $obj = Bio::EnsEMBL::G2P::TextMiningDisease->new(
      -text_mining_disease_id => $row->{text_mining_disease_id},
      -publication_id => $row->{publication_id},
      -mesh_id => $row->{mesh_id},
      -annotated_text => $row->{annotated_text},
      -source => $row->{source},
      -adaptor => $self,
    );

    $self->{_temp_objs}{$row->{text_mining_disease_id}} = $obj;
  }

  # Add a synonym if available
  if (defined $row->{phenotype_id} ) {
    $obj->add_phenotype_id($row->{phenotype_id});
  }

  $obj->mesh_stable_id($row->{mesh_stable_id});
  $obj->mesh_name($row->{mesh_name});
}

1;
