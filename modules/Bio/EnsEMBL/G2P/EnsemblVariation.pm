=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute
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

package Bio::EnsEMBL::G2P::EnsemblVariation;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($ensembl_variation_id, $genomic_feature_id, $seq_region, $seq_region_start, $seq_region_end, $seq_region_strand, $name, $source, $allele_string, $consequence, $feature_stable_id, $amino_acid_string, $polyphen_prediction, $sift_prediction, $adaptor) = rearrange(['ensembl_variation_id', 'genomic_feature_id', 'seq_region', 'seq_region_start', 'seq_region_end', 'seq_region_strand', 'name', 'source', 'allele_string', 'consequence', 'feature_stable_id', 'amino_acid_string', 'polyphen_prediction', 'sift_prediction', 'adaptor'], @_);

  my $self = bless {
    'ensembl_variation_id' => $ensembl_variation_id,
    'genomic_feature_id' => $genomic_feature_id,
    'seq_region' => $seq_region,
    'seq_region_start' => $seq_region_start,
    'seq_region_end' => $seq_region_end,
    'seq_region_strand' => $seq_region_strand,
    'name' => $name,
    'source' => $source,
    'allele_string' => $allele_string,
    'consequence' => $consequence,
    'feature_stable_id' => $feature_stable_id,
    'amino_acid_string' => $amino_acid_string,
    'polyphen_prediction' => $polyphen_prediction,
    'sift_prediction' => $sift_prediction,
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub ensembl_variation_id {
  my $self = shift;
  $self->{ensembl_variation_id} = shift if ( @_ );
  return $self->{ensembl_variation_id};
}

sub genomic_feature_id {
  my $self = shift;
  $self->{genomic_feature_id} = shift if ( @_ );
  return $self->{genomic_feature_id};
}

sub seq_region {
  my $self = shift;
  $self->{seq_region} = shift if ( @_ );
  return $self->{seq_region};
}

sub seq_region_start {
  my $self = shift;
  $self->{seq_region_start} = shift if ( @_ );
  return $self->{seq_region_start};
}

sub seq_region_end {
  my $self = shift;
  $self->{seq_region_end} = shift if ( @_ );
  return $self->{seq_region_end};
}

sub seq_region_strand {
  my $self = shift;
  $self->{seq_region_strand} = shift if ( @_ );
  return $self->{seq_region_strand};
}

sub name {
  my $self = shift;
  $self->{name} = shift if ( @_ );
  return $self->{name};
}

sub source {
  my $self = shift;
  $self->{source} = shift if ( @_ );
  return $self->{source};
}

sub allele_string {
  my $self = shift;
  $self->{allele_string} = shift if ( @_ );
  return $self->{allele_string};
}

sub consequence {
  my $self = shift;
  $self->{consequence} = shift if ( @_ );
  return $self->{consequence};
}

sub feature_stable_id {
  my $self = shift;
  $self->{feature_stable_id} = shift if ( @_ );
  return $self->{feature_stable_id};
}

sub amino_acid_string {
  my $self = shift;
  $self->{amino_acid_string} = shift if ( @_ );
  return $self->{amino_acid_string};
}

sub polyphen_prediction {
  my $self = shift;
  $self->{polyphen_prediction} = shift if ( @_ );
  return $self->{polyphen_prediction};
}

sub sift_prediction {
  my $self = shift;
  $self->{sift_prediction} = shift if ( @_ );
  return $self->{sift_prediction};
}

1;
