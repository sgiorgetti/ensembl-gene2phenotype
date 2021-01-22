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

package Bio::EnsEMBL::G2P::DBSQL::PlaceholderFeatureAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::PlaceholderFeature;
use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my ($self, $placeholder_feature) = @_;
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO placeholder_feature (
      placeholder_name,
      gene_symbol,
      gene_feature_id,
      disease_id,
      panel_id,
      seq_region_name,
      seq_region_start,
      seq_region_end,
      seq_region_strand
    ) VALUES (?,?,?,?,?,?,?,?,?)
  });

  $sth->execute(
    $placeholder_feature->placeholder_name,
    $placeholder_feature->gene_symbol,
    $placeholder_feature->gene_feature_id,
    $placeholder_feature->disease_id,
    $placeholder_feature->panel_id,
    $placeholder_feature->seq_region_name,
    $placeholder_feature->seq_region_start,
    $placeholder_feature->seq_region_end,
    $placeholder_feature->seq_region_strand,
  );

  $sth->finish;

  my $dbID = $dbh->last_insert_id(undef, undef, 'placeholder_feature', 'placeholder_feature_id');
  $placeholder_feature->{dbID}    = $dbID;
  $placeholder_feature->{adaptor} = $self;
  return $placeholder_feature;
}

sub fetch_all {
  my $self = shift;
  return $self->generic_fetch();
}

sub fetch_by_dbID {
  my $self = shift;
  my $allele_feature_id = shift;
  return $self->SUPER::fetch_by_dbID($allele_feature_id);
}

sub fetch_by_gene_feature_id_disease_id_panel_id {
  my ($self, $gene_feature_id, $disease_id, $panel_id) = @_;
  my $constraint = "pf.gene_feature_id='$gene_feature_id' AND pf.disease_id=$disease_id AND pf.panel_id=$panel_id;";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub _columns {
  my $self = shift;
  my @cols = (
    'pf.placeholder_feature_id',
    'pf.placeholder_name',
    'pf.gene_symbol',
    'pf.gene_feature_id',
    'pf.disease_id',
    'pf.panel_id',
    'pf.seq_region_name',
    'pf.seq_region_start',
    'pf.seq_region_end',
    'pf.seq_region_strand',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['placeholder_feature', 'pf'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($placeholder_feature_id, $placeholder_name, $gene_symbol, $gene_feature_id, $disease_id, $panel_id, $seq_region_name, $seq_region_start, $seq_region_end, $seq_region_strand);
  $sth->bind_columns(\($placeholder_feature_id, $placeholder_name, $gene_symbol, $gene_feature_id, $disease_id, $panel_id, $seq_region_name, $seq_region_start, $seq_region_end, $seq_region_strand));

  my @objs;
  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::PlaceholderFeature->new(
      -placeholder_feature_id => $placeholder_feature_id,
      -placeholder_name => $placeholder_name,
      -gene_symbol => $gene_symbol,
      -gene_feature_id => $gene_feature_id,
      -disease_id => $disease_id,
      -panel_id => $panel_id,
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
