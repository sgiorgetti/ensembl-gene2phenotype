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

package Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureAdaptor;

use Bio::EnsEMBL::G2P::GenomicFeature;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my ($self, $GF) = @_;
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature (
      gene_symbol,
      mim,
      ensembl_stable_id,
      seq_region_id,
      seq_region_start,
      seq_region_end,
      seq_region_strand
    ) VALUES (?,?,?,?,?,?,?)
  });

  $sth->execute(
    $GF->gene_symbol,
    $GF->mim,
    $GF->ensembl_stable_id,
    $GF->{seq_region_id} || undef,
    $GF->{seq_region_start} || undef,
    $GF->{seq_region_end} || undef,
    $GF->{seq_region_strand} || undef,
  );

  $sth->finish;

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature', 'genomic_feature_id');
  $GF->{dbID}    = $dbID;
  $GF->{adaptor} = $self;
}

sub fetch_all {
  my $self = shift;
  return $self->generic_fetch();
}

sub fetch_by_dbID {
  my $self = shift;
  my $genomic_feature_id = shift;
  return $self->SUPER::fetch_by_dbID($genomic_feature_id);
}

sub fetch_by_mim {
  my $self = shift;
  my $mim = shift;
  my $constraint = qq{gf.mim = ?};
  $self->bind_param_generic_fetch($mim, SQL_VARCHAR);
  my $result =  $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_by_gene_symbol {
  my $self = shift;
  my $gene_symbol = shift;
  my $constraint = qq{gf.gene_symbol = ?};
  $self->bind_param_generic_fetch($gene_symbol, SQL_VARCHAR);
  my $result =  $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_by_ensembl_stable_id {
  my $self = shift;
  my $ensembl_stable_id = shift;
  my $constraint = qq{gf.ensembl_stable_id = ?};
  $self->bind_param_generic_fetch($ensembl_stable_id, SQL_VARCHAR);
  my $result =  $self->generic_fetch($constraint);
  return $result->[0];
}

sub _columns {
  my $self = shift;
  my @cols = (
    'gf.genomic_feature_id',
    'gf.gene_symbol',
    'gf.mim',
    'gf.ensembl_stable_id',
    'gf.seq_region_id',
    'gf.seq_region_start',
    'gf.seq_region_end',
    'gf.seq_region_strand',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['genomic_feature', 'gf'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($genomic_feature_id, $gene_symbol, $mim, $ensembl_stable_id, $seq_region_id, $seq_region_start, $seq_region_end, $seq_region_strand);
  $sth->bind_columns(\($genomic_feature_id, $gene_symbol, $mim, $ensembl_stable_id, $seq_region_id, $seq_region_start, $seq_region_end, $seq_region_strand));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::GenomicFeature->new(
      -genomic_feature_id => $genomic_feature_id,
      -gene_symbol => $gene_symbol,
      -mim => $mim,
      -ensembl_stable_id => $ensembl_stable_id,      
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
