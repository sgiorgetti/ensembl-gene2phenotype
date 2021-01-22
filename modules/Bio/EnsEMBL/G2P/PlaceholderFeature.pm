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

package Bio::EnsEMBL::G2P::PlaceholderFeature;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my ($adaptor, $placeholder_feature_id, $placeholder_name, $gene_symbol, $gene_feature_id, $disease_id, $panel_id, $seq_region_name, $seq_region_start, $seq_region_end, $seq_region_strand) = 
    rearrange(['adaptor', 'placeholder_feature_id', 'placeholder_name', 'gene_symbol', 'gene_feature_id', 'disease_id', 'panel_id', 'seq_region_name', 'seq_region_start', 'seq_region_end', 'seq_region_strand'], @_);

  my $self = bless {
    'dbID' => $placeholder_feature_id,
    'placeholder_feature_id' => $placeholder_feature_id,
    'placeholder_name' => $placeholder_name,
    'gene_symbol' => $gene_symbol,
    'gene_feature_id' => $gene_feature_id,
    'disease_id' => $disease_id,
    'panel_id' => $panel_id,
    'seq_region_name' => $seq_region_name,
    'seq_region_start' => $seq_region_start,
    'seq_region_end' => $seq_region_end,
    'seq_region_strand' => $seq_region_strand,
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  $self->{dbID} = shift if @_;
  return $self->{dbID};
}

sub placeholder_feature_id {
  my $self = shift;
  $self->{placeholder_feature_id} = shift if @_;
  return $self->{placeholder_feature_id};
}

sub placeholder_name {
  my $self = shift;
  $self->{placeholder_name} = shift if @_;
  if (!defined $self->{placeholder_name}) {
    $self->{placeholder_name} = join('_', 'placeholder', $self->get_GeneFeature->gene_symbol, $self->get_Disease->dbID, $self->get_Panel->name);
  }
  return $self->{placeholder_name};
}

sub gene_symbol {
  my $self = shift;
  $self->{gene_symbol} = shift if @_;
  return $self->{gene_symbol};
}

sub gene_feature_id {
  my $self = shift;
  $self->{gene_feature_id} = shift if @_;
  return $self->{gene_feature_id};
}

sub disease_id {
  my $self = shift;
  $self->{disease_id} = shift if @_;
  return $self->{disease_id};
}

sub panel_id {
  my $self = shift;
  $self->{panel_id} = shift if @_;
  return $self->{panel_id};
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

sub get_GeneFeature {
  my $self = shift;
  my $gene_feature_adaptor = $self->{adaptor}->db->get_GeneFeatureAdaptor;
  return $gene_feature_adaptor->fetch_by_dbID($self->gene_feature_id);
}

sub get_Disease {
  my $self = shift;
  my $disease_adaptor = $self->{adaptor}->db->get_DiseaseAdaptor;
  return $disease_adaptor->fetch_by_dbID($self->disease_id);
}

sub get_Panel {
  my $self = shift;
  my $panel_adaptor = $self->{adaptor}->db->get_PanelAdaptor;
  return $panel_adaptor->fetch_by_dbID($self->panel_id);
}

1;
