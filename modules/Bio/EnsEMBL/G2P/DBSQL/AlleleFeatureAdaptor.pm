=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2020] EMBL-European Bioinformatics Institute
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

package Bio::EnsEMBL::G2P::DBSQL::AlleleFeatureAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;

use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my ($self, $allele_feature) = @_;
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO allele_feature (
      seq_region_name,
      seq_region_start,
      seq_region_end,
      seq_region_strand,
      name,
      ref_allele,
      alt_allele,
      hgvs_genomic
    ) VALUES (?,?,?,?,?,?,?,?)
  });



  $sth->execute(
    $allele_feature->seq_region_name,
    $allele_feature->seq_region_start,
    $allele_feature->seq_region_end,
    (defined $allele_feature->seq_region_strand) ? $allele_feature->seq_region_strand : 1,
    $allele_feature->name,
    $allele_feature->ref_allele,
    $allele_feature->alt_allele,
    $allele_feature->hgvs_genomic
  );

  $sth->finish;

  my $dbID = $dbh->last_insert_id(undef, undef, 'allele_feature', 'allele_feature_id');
  $allele_feature->{dbID}    = $dbID;
  $allele_feature->{adaptor} = $self;
  return $allele_feature;
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

sub fetch_by_name_and_hgvs_genomic {
  my ($self, $name, $hgvs_genomic) = @_;
  my $constraint = "af.name='$name' AND af.hgvs_genomic='$hgvs_genomic';";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub _columns {
  my $self = shift;
  my @cols = (
    'af.allele_feature_id',
    'af.seq_region_name',
    'af.seq_region_start',
    'af.seq_region_end',
    'af.seq_region_strand',
    'af.name',
    'af.ref_allele',
    'af.alt_allele',
    'af.hgvs_genomic'
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['allele_feature', 'af'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($allele_feature_id, $seq_region_name, $seq_region_start, $seq_region_end, $seq_region_strand, $name, $ref_allele, $alt_allele, $hgvs_genomic);
  $sth->bind_columns(\($allele_feature_id, $seq_region_name, $seq_region_start, $seq_region_end, $seq_region_strand, $name, $ref_allele, $alt_allele, $hgvs_genomic));

  my @objs;
  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::AlleleFeature->new(
      -allele_feature_id => $allele_feature_id,
      -seq_region_name => $seq_region_name,
      -seq_region_start => $seq_region_start,
      -seq_region_end => $seq_region_end,
      -seq_region_strand => $seq_region_strand,
      -name => $name,
      -ref_allele => $ref_allele,
      -alt_allele => $alt_allele,
      -hgvs_genomic => $hgvs_genomic,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}


1;
