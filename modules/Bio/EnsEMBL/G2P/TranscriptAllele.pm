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

package Bio::EnsEMBL::G2P::TranscriptAllele;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my ($adaptor, $transcript_allele_id, $allele_feature_id, $gene_feature_id, $transcript_stable_id, $consequence_types, $cds_start, $cds_end, $cdna_start, $cdna_end, $translation_start, $translation_end, $codon_allele_string, $pep_allele_string, $hgvs_transcript, $hgvs_protein, $cadd, $sift_prediction, $polyphen_prediction, $appris, $tsl, $mane) = rearrange(['adaptor', 'transcript_allele_id', 'allele_feature_id', 'gene_feature_id', 'transcript_stable_id', 'consequence_types', 'cds_start', 'cds_end', 'cdna_start', 'cdna_end', 'translation_start', 'translation_end', 'codon_allele_string', 'pep_allele_string', 'hgvs_transcript', 'hgvs_protein', 'cadd', 'sift_prediction', 'polyphen_prediction', 'appris', 'tsl', 'mane'], @_);

  my $self = bless {
    'dbID' => $transcript_allele_id,
    'allele_feature_id' => $allele_feature_id,
    'gene_feature_id' => $gene_feature_id,
    'transcript_stable_id' => $transcript_stable_id,
    'consequence_types' => $consequence_types,
    'cds_start' => $cds_start,
    'cds_end' => $cds_end,
    'cdna_start' => $cdna_start,
    'cdna_end' => $cdna_end,
    'translation_start' => $translation_start,
    'translation_end' => $translation_end,
    'codon_allele_string' => $codon_allele_string,
    'pep_allele_string' => $pep_allele_string,
    'hgvs_transcript' => $hgvs_transcript,
    'hgvs_protein' => $hgvs_protein,
    'cadd' => $cadd,
    'sift_prediction' => $sift_prediction,
    'polyphen_prediction' => $polyphen_prediction,
    'appris' => $appris,
    'tsl' => $tsl,
    'mane' => $mane,
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  $self->{transcript_allele_id} = shift if @_;
  return $self->{transcript_allele_id};
}

sub allele_feature_id {
  my $self = shift;
  $self->{allele_feature_id} = shift if @_;
  return $self->{allele_feature_id};
}

sub gene_feature_id {
  my $self = shift;
  $self->{gene_feature_id} = shift if @_;
  return $self->{gene_feature_id};
}

sub transcript_stable_id {
  my $self = shift;
  $self->{transcript_stable_id} = shift if @_;
  return $self->{transcript_stable_id};
}

sub consequence_types {
  my $self = shift;
  $self->{consequence_types} = shift if @_;
  return $self->{consequence_types};
}

sub cds_start {
  my $self = shift;
  $self->{cds_start} = shift if @_;
  return $self->{cds_start};
}

sub cds_end {
  my $self = shift;
  $self->{cds_end} = shift if @_;
  return $self->{cds_end};
}

sub cdna_start {
  my $self = shift;
  $self->{cdna_start} = shift if @_;
  return $self->{cdna_start};
}

sub cdna_end {
  my $self = shift;
  $self->{cdna_end} = shift if @_;
  return $self->{cdna_end};
}

sub translation_start {
  my $self = shift;
  $self->{translation_start} = shift if @_;
  return $self->{translation_start};
}

sub translation_end {
  my $self = shift;
  $self->{translation_end} = shift if @_;
  return $self->{translation_end};
}

sub codon_allele_string {
  my $self = shift;
  $self->{codon_allele_string} = shift if @_;
  return $self->{codon_allele_string};
}

sub pep_allele_string {
  my $self = shift;
  $self->{pep_allele_string} = shift if @_;
  return $self->{pep_allele_string};
}

sub hgvs_transcript {
  my $self = shift;
  $self->{hgvs_transcript} = shift if @_;
  return $self->{hgvs_transcript};
}

sub hgvs_protein {
  my $self = shift;
  $self->{hgvs_protein} = shift if @_;
  return $self->{hgvs_protein};
}

sub cadd {
  my $self = shift;
  $self->{cadd} = shift if @_;
  return $self->{cadd};
}

sub sift_prediction {
  my $self = shift;
  $self->{sift_prediction} = shift if @_;
  return $self->{sift_prediction};
}

sub polyphen_prediction {
  my $self = shift;
  $self->{polyphen_prediction} = shift if @_;
  return $self->{polyphen_prediction};
}

sub appris {
  my $self = shift;
  $self->{appris} = shift if @_;
  return $self->{appris};
}

sub tsl {
  my $self = shift;
  $self->{tsl} = shift if @_;
  return $self->{tsl};
}

sub mane {
  my $self = shift;
  $self->{mane} = shift if @_;
  return $self->{mane};
}

1;
