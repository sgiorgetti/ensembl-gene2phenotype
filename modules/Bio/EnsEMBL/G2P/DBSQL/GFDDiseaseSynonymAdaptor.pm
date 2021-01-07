=head1 LICENSE
 
See the NOTICE file distributed with this work for additional information
regarding copyright ownership.
 
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

package Bio::EnsEMBL::G2P::DBSQL::GFDDiseaseSynonymAdaptor;

use Bio::EnsEMBL::G2P::GFDDiseaseSynonym;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $gfd_disease_synonym = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($gfd_disease_synonym) || !$gfd_disease_synonym->isa('Bio::EnsEMBL::G2P::GFDDiseaseSynonym')) {
    die('Bio::EnsEMBL::G2P::GFDDiseaseSynonym arg expected');
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO GFD_disease_synonym(
      genomic_feature_disease_id,
      disease_id
    ) VALUES (?, ?)
  });

  $sth->execute(
    $gfd_disease_synonym->{genomic_feature_disease_id},
    $gfd_disease_synonym->{disease_id}
  );

  $sth->finish();
  
  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'gfd_disease_synonym', 'GFD_disease_synonym_id'); 
  $gfd_disease_synonym->{GFD_disease_synonym_id} = $dbID;

  return $gfd_disease_synonym;
}

sub fetch_by_dbID {
  my $self = shift;
  my $gfd_disease_synonym_id = shift;
  return $self->SUPER::fetch_by_dbID($gfd_disease_synonym_id);
}

sub fetch_all_by_GenomicFeatureDisease {
  my $self = shift;
  my $gfd = shift;
  my $gfd_id = $gfd->dbID;
  my $constraint = "gfdds.genomic_feature_disease_id=$gfd_id";
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'gfdds.gfd_disease_synonym_id',
    'gfdds.genomic_feature_disease_id',
    'gfdds.disease_id',
    'd.name'
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['GFD_disease_synonym', 'gfdds'],
    ['disease', 'd']
  );
  return @tables;
}

sub _left_join {
  my $self = shift;

  my @left_join = (
    ['disease', 'gfdds.disease_id = d.disease_id'],
  );
  return @left_join;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($gfd_disease_synonym_id, $genomic_feature_disease_id, $disease_id, $synonym);
  $sth->bind_columns(\($gfd_disease_synonym_id, $genomic_feature_disease_id, $disease_id, $synonym));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::GFDDiseaseSynonym->new(
      -GFD_disease_synonym_id => $gfd_disease_synonym_id,
      -genomic_feature_disease_id => $genomic_feature_disease_id,
      -disease_id => $disease_id,
      -synonym => $synonym,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
