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

package Bio::EnsEMBL::G2P::LocationFeature;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($location_feature_id, $seq_region_name, $seq_region_start, $seq_region_end, $seq_region_strand, $adaptor) =
    rearrange(['location_feature_id', 'seq_region_name', 'seq_region_start', 'seq_region_end', 'seq_region_strand', 'adaptor'], @_);
  
  my $self = bless {
    'dbID' => $location_feature_id,
    'location_feature_id' => $location_feature_id,
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
  $self->{location_feature_id} = shift if @_;
  return $self->{location_feature_id};
}

sub location_feature_id {
  my $self = shift;
  $self->{location_feature_id} = shift if @_;
  return $self->{location_feature_id};
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

1;
