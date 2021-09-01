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

package Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseasePanelLogAdaptor;

use Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanelLog;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

=head2 store

  Arg [1]    : Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanelLog $gfd_panel_log
  Example    : $gfd_panel_log = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanelLog->new(...);
               $gfd_panel_log = $gfd_panel_log_adaptor->store($gfd_panel_log);
  Description: This stores a GenomicFeatureDiseasePanelLog in the database.
  Returntype : Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanelLog
  Exceptions : - Throw error if $gfd_panel_log is not a
                 Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanelLog
  Caller     : Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanelAdaptor::update_log
  Status     : Stable

=cut

sub store {
  my $self = shift;
  my $gfd_panel_log = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($gfd_panel_log) || !$gfd_panel_log->isa('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanelLog')) {
    die('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanelLog arg expected');
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_panel_log(
      genomic_feature_disease_panel_id,
      genomic_feature_disease_id,
      original_confidence_category_attrib,
      confidence_category_attrib,
      clinical_review,
      is_visible,
      panel_attrib,
      created,
      user_id,
      action
    ) VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?, ?)
  });

  $sth->execute(
    $gfd_panel_log->{genomic_feature_disease_panel_id},
    $gfd_panel_log->genomic_feature_disease_id,
    $gfd_panel_log->{original_confidence_category_attrib},
    $gfd_panel_log->{confidence_category_attrib},
    $gfd_panel_log->clinical_review,
    $gfd_panel_log->is_visible || 1,
    $gfd_panel_log->{panel_attrib},
    $gfd_panel_log->user_id,
    $gfd_panel_log->action,
  );

  $sth->finish();
  
  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease_panel_log', 'genomic_feature_disease_panel_log_id'); 
  $gfd_panel_log->{genomic_feature_disease_panel_log_id} = $dbID;

  return $gfd_panel_log;
}

sub fetch_by_dbID {
  my $self = shift;
  my $dbID = shift;
  return $self->SUPER::fetch_by_dbID($dbID);
}

sub fetch_all_by_GenomicFeatureDiseasePanel {
  my $self = shift;
  my $gfd_panel = shift;
  my $gfd_panel_id = $gfd_panel->dbID;
  my $constraint = "gfdpl.genomic_feature_disease_panel_id=$gfd_panel_id";
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_most_recent {
  my $self = shift;
  my $panel = shift;
  my $limit = shift;
  my $is_visible_only = shift;
  my $action = shift;
  $limit ||= 10;
  $is_visible_only ||= 1;
  $action ||= 'create';

  my $attribute_adaptor = $self->db->get_AttributeAdaptor;
  my $panel_attrib = $attribute_adaptor->get_attrib('g2p_panel', $panel);
  my $constraint = "gfdpl.panel_attrib='$panel_attrib' AND gfdpl.action='$action'";
  if ($is_visible_only) {
    $constraint .= " AND gfdpl.is_visible = 1";
  }
  $constraint .= " ORDER BY created DESC limit $limit";
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'gfdpl.genomic_feature_disease_panel_log_id',
    'gfdpl.genomic_feature_disease_panel_id',
    'gfdpl.genomic_feature_disease_id',
    'gfdpl.original_confidence_category_attrib',
    'gfdpl.confidence_category_attrib',
    'gfdpl.clinical_review',
    'gfdpl.is_visible',
    'gfdpl.panel_attrib',
    'gfdpl.created',
    'gfdpl.user_id',
    'gfdpl.action',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['genomic_feature_disease_panel_log', 'gfdpl'],
  );
  return @tables;
}
sub _left_join {
  my $self = shift;

  my @left_join = (
  );
  return @left_join;
}

=head2 _objs_from_sth

  Arg [1]    : StatementHandle $sth
  Description: Responsible for the creation of GenomicFeatureDiseasePanelLogs
  Returntype : listref of Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanelLog
  Exceptions : None
  Caller     : Internal
  Status     : Stable

=cut

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my (
    $genomic_feature_disease_panel_log_id,
    $genomic_feature_disease_panel_id,
    $genomic_feature_disease_id,
    $original_confidence_category_attrib,
    $confidence_category_attrib,
    $clinical_review,
    $is_visible,
    $panel_attrib,
    $created,
    $user_id,
    $action,
  );
  $sth->bind_columns(\(
    $genomic_feature_disease_panel_log_id,
    $genomic_feature_disease_panel_id,
    $genomic_feature_disease_id,
    $original_confidence_category_attrib,
    $confidence_category_attrib,
    $clinical_review,
    $is_visible,
    $panel_attrib,
    $created,
    $user_id,
    $action,
  ));

  my @objs;

  my $attribute_adaptor = $self->db->get_AttributeAdaptor;

  while ($sth->fetch()) {
    my $confidence_category = undef; 
    my $obj = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanelLog->new(
      -genomic_feature_disease_panel_log_id => $genomic_feature_disease_panel_log_id,
      -genomic_feature_disease_panel_id => $genomic_feature_disease_panel_id,
      -genomic_feature_disease_id => $genomic_feature_disease_id,
      -original_confidence_category_attrib => $original_confidence_category_attrib,
      -confidence_category_attrib => $confidence_category_attrib,
      -clinical_review => $clinical_review,
      -is_visible => $is_visible,
      -panel_attrib => $panel_attrib,
      -created => $created,
      -user_id => $user_id,
      -action => $action,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
