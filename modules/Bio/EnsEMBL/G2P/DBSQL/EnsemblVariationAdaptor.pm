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

package Bio::EnsEMBL::G2P::DBSQL::EnsemblVariationAdaptor;

use Bio::EnsEMBL::G2P::EnsemblVariation;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $variation = shift;  
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO ensembl_variant (
      genomic_feature_id,
      seq_region,
      seq_region_start,
      seq_region_end,
      seq_region_strand,
      name,
      source,
      allele_string,
      consequence,
      feature_stable_id,
      amino_acid_string,
      polyphen_prediction,
      sift_prediction
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
  });
  $sth->execute(
    $variation->genomic_feature_id,
    $variation->seq_region,
    $variation->seq_region_start,
    $variation->seq_region_end,
    $variation->seq_region_strand,
    $variation->name,
    $variation->source,
    $variation->allele_string,
    $variation->consequence,
    $variation->feature_stable_id,
    $variation->amino_acid_string || undef,
    $variation->polyphen_prediction || undef,
    $variation->sift_prediction || undef,  
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'ensemblvariation', 'variation_id');
  $variation->{ensembl_variation_id} = $dbID;
  return $variation;
}

sub fetch_all_by_GenomicFeature {
  my $self = shift;
  my $gf = shift;
  my $constraint = "v.genomic_feature_id=" . $gf->dbID;
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'v.ensembl_variation_id',
    'v.genomic_feature_id',
    'v.seq_region',
    'v.seq_region_start',
    'v.seq_region_end',
    'v.seq_region_strand',
    'v.name',
    'v.source',
    'v.allele_string',
    'v.consequence',
    'v.feature_stable_id',
    'v.amino_acid_string',
    'v.polyphen_prediction',
    'v.sift_prediction',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['ensembl_variation', 'v'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($ensembl_variation_id, $genomic_feature_id, $seq_region, $seq_region_start, $seq_region_end, $seq_region_strand, $name, $source, $allele_string, $consequence, $feature_stable_id, $amino_acid_string, $polyphen_prediction, $sift_prediction);
  $sth->bind_columns(\($ensembl_variation_id, $genomic_feature_id, $seq_region, $seq_region_start, $seq_region_end, $seq_region_strand, $name, $source, $allele_string, $consequence, $feature_stable_id, $amino_acid_string, $polyphen_prediction, $sift_prediction));

  my @objs;
  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::EnsemblVariation->new(
      -ensembl_variation_id => $ensembl_variation_id,
      -genomic_feature_id => $genomic_feature_id,
      -seq_region => $seq_region,
      -seq_region_start => $seq_region_start,
      -seq_region_end => $seq_region_end,
      -seq_region_strand => $seq_region_strand,
      -name => $name,
      -source => $source,
      -allele_string => $allele_string,
      -consequence => $consequence,
      -feature_stable_id => $feature_stable_id,
      -amino_acid_string => $amino_acid_string,
      -polyphen_prediction => $polyphen_prediction,
      -sift_prediction => $sift_prediction,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
