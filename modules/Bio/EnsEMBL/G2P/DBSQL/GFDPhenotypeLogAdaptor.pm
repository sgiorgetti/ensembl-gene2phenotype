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

package Bio::EnsEMBL::G2P::DBSQL::GFDPhenotypeLogAdaptor;

use Bio::EnsEMBL::G2P::GFDPhenotypeLog;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

=head2 store

  Arg [1]    : Bio::EnsEMBL::G2P::GFDPhenotypeLog $gfd_phenotype_log
  Example    : $gfd_phenotype_log = Bio::EnsEMBL::G2P::GFDPhenotypeLog->new(...);
               $gfd_phenotype_log = $gfd_phenotype_log_adaptor->store($gfd_log);
  Description: This stores a GFDPhenotypeLog in the database.
  Returntype : Bio::EnsEMBL::G2P::GFDPhenotypeLog
  Exceptions : - Throw error if $gfd_phenotype_log is not a
                 Bio::EnsEMBL::G2P::GFDPhenotypeLog
  Caller     : Bio::EnsEMBL::G2P::GenomicFeatureDiseasePhenotypeAdaptor::update_log
  Status     : Stable

=cut

sub store {
  my $self = shift;
  my $gfd_phenotype_log = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($gfd_phenotype_log) || !$gfd_phenotype_log->isa('Bio::EnsEMBL::G2P::GFDPhenotypeLog')) {
    die('Bio::EnsEMBL::G2P::GFDPhenotypeLog arg expected');
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO GFD_phenotype_log(
      genomic_feature_disease_phenotype_id,
      genomic_feature_disease_id,
      phenotype_id,
      created,
      user_id,
      action
    ) VALUES (?, ?, ?, CURRENT_TIMESTAMP, ?, ?)
  });

  $sth->execute(
    $gfd_phenotype_log->{genomic_feature_disease_phenotype_id},
    $gfd_phenotype_log->{genomic_feature_disease_id},
    $gfd_phenotype_log->{phenotype_id},
    $gfd_phenotype_log->user_id,
    $gfd_phenotype_log->action,
  );

  $sth->finish();
  
  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'gfd_phenotype_log', 'GFD_phenotype_log_id'); 
  $gfd_phenotype_log->{GFD_phenotype_log_id} = $dbID;

  return $gfd_phenotype_log;
}

sub fetch_by_dbID {
  my $self = shift;
  my $genomic_feature_disease_phenotype_id = shift;
  return $self->SUPER::fetch_by_dbID($genomic_feature_disease_phenotype_id);
}

sub fetch_all_by_GenomicFeatureDisease {
  my $self = shift;
  my $gfd = shift;
  my $gfd_id = $gfd->dbID;
  my $constraint = "gfdpl.genomic_feature_disease_id=$gfd_id";
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_GenomicFeatureDiseasePhenotype {
  my $self = shift;
  my $gfd_phenotype = shift;
  my $gfd_phenotype_id = $gfd_phenotype->dbID;
  my $constraint = "gfdpl.genomic_feature_disease_phenotype_id=$gfd_phenotype_id";
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'gfdpl.gfd_phenotype_log_id',
    'gfdpl.genomic_feature_disease_phenotype_id',
    'gfdpl.genomic_feature_disease_id',
    'gfdpl.phenotype_id',
    'gfdpl.created',
    'gfdpl.user_id',
    'gfdpl.action'
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['GFD_phenotype_log', 'gfdpl'],
  );
  return @tables;
}

=head2 _objs_from_sth

  Arg [1]    : StatementHandle $sth
  Description: Responsible for the creation of GFDPhenotypeLogs
  Returntype : listref of Bio::EnsEMBL::G2P::GFDPhenotypeLog
  Exceptions : None
  Caller     : Internal
  Status     : Stable

=cut

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($gfd_phenotype_log_id, $genomic_feature_disease_phenotype_id, $genomic_feature_disease_id, $phenotype_id, $created, $user_id, $action);

  $sth->bind_columns(\($gfd_phenotype_log_id, $genomic_feature_disease_phenotype_id, $genomic_feature_disease_id, $phenotype_id, $created, $user_id, $action));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::GFDPhenotypeLog->new(
      -GFD_phenotype_log_id => $gfd_phenotype_log_id,
      -genomic_feature_disease_phenotype_id => $genomic_feature_disease_phenotype_id,
      -genomic_feature_disease_id => $genomic_feature_disease_id,
      -phenotype_id => $phenotype_id,
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
