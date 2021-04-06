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

package Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanelLog;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use base qw(Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel);

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my (
    $genomic_feature_disease_panel_log_id,
    $genomic_feature_disease_panel_id,
    $genomic_feature_disease_id,
    $confidence_category_attrib,
    $is_visible,
    $panel_attrib,
    $created,
    $user_id,
    $action,
    $adaptor,
  ) = rearrange([
    'genomic_feature_disease_panel_log_id',
    'genomic_feature_disease_panel_id',
    'genomic_feature_disease_id',
    'confidence_category_attrib',
    'is_visible',
    'panel_attrib',
    'created',
    'user_id',
    'action',
    'adaptor',
  ], @_);
  my $self = $class->SUPER::new(@_);
  $self->{created} =  $created;
  return $self;
}

sub dbID {
  my $self = shift;
  $self->{genomic_feature_disease_panel_id} = shift if ( @_ );
  return $self->{genomic_feature_disease_panel_id};
}

sub genomic_feature_disease_id {
  my $self = shift;
  $self->{genomic_feature_disease_id} = shift if ( @_ );
  return $self->{genomic_feature_disease_id};
}

sub confidence_category {
  my $self = shift;
  my $confidence_category = shift;
  if ($confidence_category) {
    my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;
    my $confidence_category_attrib = $attribute_adaptor->attrib_id_for_value($confidence_category);
    die "Could not get confidence category attrib id for value $confidence_category\n" unless ($confidence_category_attrib);
    $self->{confidence_category} = $confidence_category;
    $self->{confidence_category_attrib} = $confidence_category_attrib;
  } else {
    if ($self->{confidence_category_attrib} && !$self->{confidence_category}) {
      my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;
      my $confidence_category = $attribute_adaptor->attrib_value_for_id($self->{confidence_category_attrib});
      $self->{confidence_category} = $confidence_category;
    }   
    die "No confidence_category" unless ($self->{confidence_category} );
  }
  return $self->{confidence_category};
}

sub confidence_category_attrib {
  my $self = shift;
  my $confidence_category_attrib = shift;
  if ($confidence_category_attrib) {
    my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;
    my $confidence_category = $attribute_adaptor->attrib_value_for_id($confidence_category_attrib);
    die "Could not get confidence category for value $confidence_category_attrib\n" unless ($confidence_category);
    $self->{confidence_category} = $confidence_category;
    $self->{confidence_category_attrib} = $confidence_category_attrib;
  } else {
    die "No confidence_category_attrib" unless ($self->{confidence_category_attrib});
  }
  return $self->{confidence_category_attrib};
}

sub is_visible {
  my $self = shift;
  $self->{is_visible} = shift if ( @_ );
  return $self->{is_visible};
}

sub panel {
  my $self = shift;
  my $panel = shift;
  if ($panel) {
    my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;
    my $panel_attrib = $attribute_adaptor->attrib_id_for_value($panel);
    die "Could not get panel attrib id for value $panel\n" unless ($panel_attrib);
    $self->{panel} = $panel;
    $self->{panel_attrib} = $panel_attrib;
  } else {
    die "No panel" unless ($self->{panel});
  }
  return $self->{panel};
}

sub panel_attrib {
  my $self = shift;
  my $panel_attrib = shift;
  if ($panel_attrib) {
    my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;
    my $panel = $attribute_adaptor->attrib_value_for_id($panel_attrib);
    die "Could not get panel for value $panel_attrib\n" unless ($panel);
    $self->{panel} = $panel;
    $self->{panel_attrib} = $panel_attrib;
  } else {
    die "No panel_attrib" unless ($self->{panel_attrib});
  }
  return $self->{panel_attrib};
}

sub created {
  my $self = shift;
  $self->{created} = shift if ( @_ );
  return $self->{created};
}

sub user_id {
  my $self = shift;
  $self->{user_id} = shift if ( @_ );
  return $self->{user_id};
}

sub action {
  my $self = shift;
  $self->{action} = shift if ( @_ );
  return $self->{action};
}

1;
