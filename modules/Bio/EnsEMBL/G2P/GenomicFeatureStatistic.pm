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

package Bio::EnsEMBL::G2P::GenomicFeatureStatistic;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my ($genomic_feature_statistic_id, $genomic_feature_id, $panel_attrib, $attribs, $adaptor) =
    rearrange(['genomic_feature_statistic_id', 'genomic_feature_id', 'panel_attrib', 'attribs', 'adaptor'], @_);

  my $self = bless {
    'dbID' => $genomic_feature_statistic_id,
    'adaptor' => $adaptor,
    'genomic_feature_id' => $genomic_feature_id,
    'panel_attrib' => $panel_attrib,
    'attribs' => $attribs,
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  $self->{genomic_feature_statistic_id} = shift if ( @_ );
  return $self->{genomic_feature_statistic_id};
}

sub genomic_feature_id {
  my $self = shift;
  $self->{genomic_feature_id} = shift if ( @_ );
  return $self->{genomic_feature_id};
}

sub panel_attrib {
  my $self = shift;
  $self->{panel_attrib} = shift if ( @_ );
  return $self->{panel_attrib};
}

sub get_all_attributes {
  my $self = shift;

  if(!defined($self->{attribs})) {
    $self->{attribs} = $self->adaptor->_fetch_attribs_by_dbID($self->dbID);
  }

  return $self->{attribs};
}

sub _set_attribute {
  my $self  = shift;
  my $key   = shift;
  my $value = shift;
  
  $self->get_all_attributes;
  $self->{attribs}->{$key} = $value;
}

sub p_value {
  my $self = shift;
  my $new  = shift;
  $self->_set_attribute('p_value', $new) if defined($new);
  return defined($self->get_all_attributes->{'p_value'}) ? $self->get_all_attributes->{'p_value'} : undef;
}

sub dataset {
  my $self = shift;
  my $new  = shift;
  $self->_set_attribute('dataset', $new) if defined($new);
  return defined($self->get_all_attributes->{'dataset'}) ? $self->get_all_attributes->{'dataset'} : undef;
}

sub clustering {
  my $self = shift;
  my $new  = shift;
  $self->_set_attribute('clustering', $new) if defined($new);
  return defined($self->get_all_attributes->{'clustering'}) ? $self->get_all_attributes->{'clustering'} : undef;
}

1;
