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

package Bio::EnsEMBL::G2P::DBSQL::LocationFeatureAdaptor;

use Bio::EnsEMBL::G2P::GenomicFeature;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;

use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my ($self, $location_feature) = @_;
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO location_feature (
      seq_region_name,
      seq_region_start,
      seq_region_end,
      seq_region_strand
    ) VALUES (?,?,?,?)
  });

  $sth->execute(
    $location_feature->seq_region_name,
    $location_feature->seq_region_start,
    $location_feature->seq_region_end,
    $location_feature->seq_region_strand,
  );

  $sth->finish;

  my $dbID = $dbh->last_insert_id(undef, undef, 'location_feature', 'location_feature_id');
  $location_feature->{dbID}    = $dbID;
  $location_feature->{adaptor} = $self;
}

sub fetch_all {
  my $self = shift;
  return $self->generic_fetch();
}

sub fetch_by_dbID {
  my $self = shift;
  my $location_feature_id = shift;
  return $self->SUPER::fetch_by_dbID($location_feature_id);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'lf.seq_region_name',
    'lf.seq_region_start',
    'lf.seq_region_end',
    'lf.seq_region_strand'
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['location_feature', 'lf'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($location_feature_id, $seq_region_name, $seq_region_start, $seq_region_end, $seq_region_strand);
  $sth->bind_columns(\($locus_feature_id, $seq_region_name, $seq_region_start, $seq_region_end, $seq_region_strand));

  my @objs;
  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::LocationFeature->new(
      -location_feature_id => $location_feature_id,
      -seq_region_name => $seq_region_name,
      -seq_region_start => $seq_region_start,
      -seq_region_end => $seq_region_end,
      -seq_region_strand => $seq_region_strand,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}


1;
