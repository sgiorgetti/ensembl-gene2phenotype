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

package Bio::EnsEMBL::G2P::AlleleFeature;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my ($adaptor, $allele_feature_id, $seq_region_name, $seq_region_start, $seq_region_end, $seq_region_strand, $name, $ref_allele, $alt_allele, $hgvs_genomic) = 
    rearrange(['adaptor', 'allele_feature_id', 'seq_region_name', 'seq_region_start', 'seq_region_end', 'seq_region_strand', 'name', 'ref_allele', 'alt_allele', 'hgvs_genomic'], @_);

  my $self = bless {
    'dbID' => $allele_feature_id,
    'allele_feature_id' => $allele_feature_id,
    'seq_region_name' => $seq_region_name,
    'seq_region_start' => $seq_region_start,
    'seq_region_end' => $seq_region_end,
    'seq_region_strand' => $seq_region_strand,
    'name' => $name,
    'ref_allele' => $ref_allele,
    'alt_allele' => $alt_allele,
    'hgvs_genomic' => $hgvs_genomic,
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  $self->{allele_feature_id} = shift if @_;
  return $self->{allele_feature_id};
}

sub allele_feature_id {
  my $self = shift;
  $self->{allele_feature_id} = shift if @_;
  return $self->{allele_feature_id};
}

sub seq_region_name {
  my $self = shift;
  $self->{seq_region_name} = shift if @_;
  return $self->{seq_region_name};
}

sub seq_region_start {
  my $self = shift;
  $self->{seq_region_start} = shift if @_;
  return $self->{seq_region_start};
}

sub seq_region_end {
  my $self = shift;
  $self->{seq_region_end} = shift if @_;
  return $self->{seq_region_end};
}

sub seq_region_strand {
  my $self = shift;
  $self->{seq_region_strand} = shift if @_;
  return $self->{seq_region_strand};
}

sub name {
  my $self = shift;
  $self->{name} = shift if @_;
  return $self->{name};
}

sub alt_allele {
  my $self = shift;
  $self->{alt_allele} = shift if @_;
  return $self->{alt_allele};
}

sub ref_allele {
  my $self = shift;
  $self->{ref_allele} = shift if @_;
  return $self->{ref_allele};
}

sub hgvs_genomic {
  my $self = shift;
  $self->{hgvs_genomic} = shift if @_;
  return $self->{hgvs_genomic};
}

1;
