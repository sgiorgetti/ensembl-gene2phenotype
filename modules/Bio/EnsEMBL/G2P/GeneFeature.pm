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

package Bio::EnsEMBL::G2P::GeneFeature;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my ($adaptor, $gene_feature_id, $seq_region_name, $seq_region_start, $seq_region_end, $seq_region_strand, $gene_symbol, $hgnc_id, $mim, $ensembl_stable_id) = 
    rearrange(['adaptor', 'gene_feature_id', 'seq_region_name', 'seq_region_start', 'seq_region_end', 'seq_region_strand', 'gene_symbol', 'hgnc_id', 'mim', 'ensembl_stable_id'], @_);

  my $self = bless {
    'dbID' => $gene_feature_id,
    'gene_feature_id' => $gene_feature_id,
    'seq_region_name' => $seq_region_name,
    'seq_region_start' => $seq_region_start,
    'seq_region_end' => $seq_region_end,
    'seq_region_strand' => $seq_region_strand,
    'gene_symbol' => $gene_symbol,
    'hgnc_id' => $hgnc_id,
    'mim' => $mim,
    'ensembl_stable_id' => $ensembl_stable_id,
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  $self->{gene_feature_id} = shift if @_;
  return $self->{gene_feature_id};
}

sub gene_feature_id {
  my $self = shift;
  $self->{gene_feature_id} = shift if @_;
  return $self->{gene_feature_id};
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

sub gene_symbol {
  my $self = shift;
  $self->{gene_symbol} = shift if @_;
  return $self->{gene_symbol};
}

sub hgnc_id {
  my $self = shift;
  $self->{hgnc_id} = shift if @_;
  return $self->{hgnc_id};
}

sub mim {
  my $self = shift;
  $self->{mim} = shift if @_;
  return $self->{mim};
}

sub ensembl_stable_id {
  my $self = shift;
  $self->{ensembl_stable_id} = shift if @_;
  return $self->{ensembl_stable_id};
}

sub add_synonym {
  my $self = shift;
  my $synonym = shift;
  $self->{'synonyms'}{$synonym}++;
  return;
}

sub get_all_synonyms {
  my $self = shift;
  my @synonyms = keys %{$self->{synonyms}};
  return \@synonyms;
}

1;
