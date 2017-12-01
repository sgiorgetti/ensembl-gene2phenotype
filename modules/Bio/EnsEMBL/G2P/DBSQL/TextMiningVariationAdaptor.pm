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

package Bio::EnsEMBL::G2P::DBSQL::TextMiningVariationAdaptor;

use Bio::EnsEMBL::G2P::TextMiningVariation;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $variation = shift;  
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO text_mining_variant (
      publication_id,
      genomic_feature_id,
      text_mining_hgvs,
      ensembl_hgvs,
      assembly,
      seq_region,
      seq_region_start,
      seq_region_end,
      seq_region_strand,
      allele_string,
      consequence,
      feature_stable_id,
      biotype,
      polyphen_prediction,
      sift_prediction,
      colocated_variants
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
  });
  $sth->execute(
    $variation->publication_id,
    $variation->genomic_feature_id,
    $variation->text_mining_hgvs,
    $variation->ensembl_hgvs,
    $variation->assembly,
    $variation->seq_region,
    $variation->seq_region_start,
    $variation->seq_region_end,
    $variation->seq_region_strand,
    $variation->allele_string,
    $variation->consequence,
    $variation->feature_stable_id,
    $variation->biotype,
    $variation->polyphen_prediction || undef,
    $variation->sift_prediction || undef,  
    $variation->colocated_variants || undef,
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'text_mining_variation', 'text_mining_variation_id');
  $variation->{text_mining_variation_id} = $dbID;
  return $variation;
}

sub fetch_all_by_Publication {
  my $self = shift;
  my $publication = shift;
  my $constraint = "tmv.publication_id=" . $publication->dbID;
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_GenomicFeature {
  my $self = shift;
  my $gf = shift;
  my $constraint = "tmv.genomic_feature_id=" . $gf->dbID;
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'tmv.text_mining_variation_id',
    'tmv.publication_id',
    'tmv.genomic_feature_id',
    'tmv.text_mining_hgvs',
    'tmv.ensembl_hgvs',
    'tmv.assembly',
    'tmv.seq_region',
    'tmv.seq_region_start',
    'tmv.seq_region_end',
    'tmv.seq_region_strand',
    'tmv.allele_string',
    'tmv.consequence',
    'tmv.feature_stable_id',
    'tmv.biotype',
    'tmv.polyphen_prediction',
    'tmv.sift_prediction',
    'tmv.colocated_variants'
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['text_mining_variation', 'tmv'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($text_mining_variation_id, $publication_id, $genomic_feature_id, $text_mining_hgvs, $ensembl_hgvs, $assembly, $seq_region, $seq_region_start, $seq_region_end, $seq_region_strand, $allele_string, $consequence, $feature_stable_id, $biotype, $polyphen_prediction, $sift_prediction, $colocated_variants);

  $sth->bind_columns(\ ($text_mining_variation_id, $publication_id, $genomic_feature_id, $text_mining_hgvs, $ensembl_hgvs, $assembly, $seq_region, $seq_region_start, $seq_region_end, $seq_region_strand, $allele_string, $consequence, $feature_stable_id, $biotype, $polyphen_prediction, $sift_prediction, $colocated_variants));

  my @objs;
  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::TextMiningVariation->new(
      -text_mining_variation_id => $text_mining_variation_id,
      -publication_id => $publication_id,
      -genomic_feature_id => $genomic_feature_id,
      -text_mining_hgvs => $text_mining_hgvs,
      -ensembl_hgvs => $ensembl_hgvs,
      -assembly => $assembly,
      -seq_region => $seq_region,
      -seq_region_start => $seq_region_start,
      -seq_region_end => $seq_region_end,
      -seq_region_strand => $seq_region_strand,
      -allele_string => $allele_string,
      -consequence => $consequence,
      -feature_stable_id => $feature_stable_id,
      -biotype => $biotype,
      -polyphen_prediction => $polyphen_prediction,
      -sift_prediction => $sift_prediction,
      -colocated_variants => $colocated_variants,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
