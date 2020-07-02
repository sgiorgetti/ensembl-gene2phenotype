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

package Bio::EnsEMBL::G2P::GeneFeature;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my ($adaptor, $gene_feature_id, $gene_symbol, $hgnc_id, $mim, $ensembl_stable_id) = 
    rearrange(['adaptor', 'gene_feature_id', 'gene_symbol', 'hgnc_id', 'mim', 'ensembl_stable_id'], @_);
  my $self = $class->SUPER::new(@_);

  $self->{'adaptor'} = $adaptor;
  $self->{'gene_feature_id'} = $gene_feature_id;
  $self->{'gene_symbol'} = $gene_symbol;
  $self->{'hgnc_id'} = $hgnc_id;
  $self->{'mim'} = $mim;
  $self->{'ensembl_stable_id'} = $ensembl_stable_id;

  return $self;
}

sub dbID {
  my $self = shift;
  $self->{gene_feature_id} = shift if @_;
  return $self->{gene_feature_id};
}

sub gene_feature_id {
  my $self = shift;
  $self->{genomic_feature_id} = shift if @_;
  return $self->{genomic_feature_id};
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
