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

package Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseActionLogAdaptor;

use Bio::EnsEMBL::G2P::GenomicFeatureDiseaseActionLog;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $gfda_log = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($gfda_log) || !$gfda_log->isa('Bio::EnsEMBL::G2P::GenomicFeatureDiseaseActionLog')) {
    die('Bio::EnsEMBL::G2P::GenomicFeatureDiseaseActionLog arg expected');
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_action_log(
      genomic_feature_disease_action_id,
      genomic_feature_disease_id,
      allelic_requirement_attrib,
      mutation_consequence_attrib,
      created,
      user_id,
      action
    ) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, ?, ?)
  });

  $sth->execute(
    $gfda_log->{genomic_feature_disease_action_id},
    $gfda_log->{genomic_feature_disease_id},
    $gfda_log->allelic_requirement_attrib || undef,
    $gfda_log->mutation_consequence_attrib || undef,
    $gfda_log->user_id,
    $gfda_log->action,
  );

  $sth->finish();
  
  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease_action_log', 'genomic_feature_disease_action_log_id'); 
  $gfda_log->{genomic_feature_disease_action_log_id} = $dbID;

  return $gfda_log;
}


sub fetch_by_dbID {
  my $self = shift;
  my $genomic_feature_disease_action_id = shift;
  return $self->SUPER::fetch_by_dbID($genomic_feature_disease_action_id);
}

sub fetch_all_by_GenomicFeatureDiseaseAction {
  my $self = shift;
  my $gfda = shift;
  my $gfda_id = $gfda->dbID;
  my $constraint = "gfdal.genomic_feature_disease_action_id=$gfda_id";
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'gfdal.genomic_feature_disease_action_log_id',
    'gfdal.genomic_feature_disease_action_id',
    'gfdal.genomic_feature_disease_id',
    'gfdal.allelic_requirement_attrib',
    'gfdal.mutation_consequence_attrib',
    'gfdal.created',
    'gfdal.user_id',
    'gfdal.action'
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['genomic_feature_disease_action_log', 'gfdal'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($genomic_feature_disease_action_log_id, $genomic_feature_disease_action_id, $genomic_feature_disease_id, $allelic_requirement_attrib, $mutation_consequence_attrib, $created, $user_id, $action);
  $sth->bind_columns(\($genomic_feature_disease_action_log_id, $genomic_feature_disease_action_id, $genomic_feature_disease_id, $allelic_requirement_attrib, $mutation_consequence_attrib, $created, $user_id, $action));

  my @objs;

  my $attribute_adaptor = $self->db->get_AttributeAdaptor;

  while ($sth->fetch()) {
   my $allelic_requirement = undef;
    my $mutation_consequence = undef;

    if ($allelic_requirement_attrib) {
      my @ids = split(',', $allelic_requirement_attrib);
      my @values = ();
      foreach my $id (@ids) {
        push @values, $attribute_adaptor->attrib_value_for_id($id);
      }
      $allelic_requirement = join(',', @values);
    }

    if ($mutation_consequence_attrib) {
      $mutation_consequence = $attribute_adaptor->attrib_value_for_id($mutation_consequence_attrib);
    }

    my $obj = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseActionLog->new(
      -genomic_feature_disease_action_log_id => $genomic_feature_disease_action_log_id,
      -genomic_feature_disease_action_id => $genomic_feature_disease_action_id,
      -genomic_feature_disease_id => $genomic_feature_disease_id,
      -allelic_requirement => $allelic_requirement,
      -allelic_requirement_attrib => $allelic_requirement_attrib,
      -mutation_consequence => $mutation_consequence,
      -mutation_consequence_attrib => $mutation_consequence_attrib,
      -adaptor => $self,
      -created => $created,
      -user_id => $user_id,
      -action => $action,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
