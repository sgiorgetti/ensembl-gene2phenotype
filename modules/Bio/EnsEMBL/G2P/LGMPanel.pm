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

package Bio::EnsEMBL::G2P::LGMPanel;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($LGM_panel_id, $locus_genotype_mechanism_id, $panel_id, $confidence_category, $confidence_category_attrib, $user_id, $created, $adaptor) =
    rearrange(['LGM_panel_id', 'locus_genotype_mechanism_id', 'panel_id', 'confidence_category', 'confidence_category_attrib', 'user_id', 'created', 'adaptor'], @_);

  my $self = bless {
    'dbID' => $LGM_panel_id,
    'LGM_panel_id' => $LGM_panel_id,
    'locus_genotype_mechanism_id' => $locus_genotype_mechanism_id,
    'panel_id' => $panel_id,
    'confidence_category' => $confidence_category,
    'confidence_category_attrib' => $confidence_category_attrib,
    'user_id' => $user_id,
    'created' => $created,
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  $self->{dbID} = shift if @_;
  return $self->{dbID};
}

sub LGM_panel_id {
  my $self = shift;
  $self->{LGM_panel_id} = shift if @_;
  return $self->{LGM_panel_id};
}

sub locus_genotype_mechanism_id {
  my $self = shift;
  $self->{locus_genotype_mechanism_id} = shift if @_;
  return $self->{locus_genotype_mechanism_id};
}

sub panel_id {
  my $self = shift;
  $self->{panel_id} = shift if @_;
  return $self->{panel_id};
}

sub get_Panel {
  my $self = shift;
  my $panel_adaptor = $self->{adaptor}->db->get_PanelAdaptor;
  return $panel_adaptor->fetch_by_dbID($self->panel_id);
}


sub confidence_category {
  my $self = shift;
  my $confidence_category = shift;
  my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;

  if ($confidence_category) {
    my $confidence_category_attrib = $attribute_adaptor->attrib_id_for_type_value('confidence_category', $confidence_category);
    $self->{confidence_category_attrib} = $confidence_category_attrib;
    $self->{confidence_category} = $confidence_category;
  } else {
    if (!$self->{confidence_category } && $self->{confidence_category_attrib} ) {
      $self->{confidence_category} = $attribute_adaptor->attrib_value_for_id($self->{confidence_category_attrib});
    }
  }
  return $self->{confidence_category};
}

sub confidence_category_attrib {
  my $self = shift;
  $self->{confidence_category_attrib} = shift if @_;
  return $self->{confidence_category_attrib};
}

sub user_id {
  my $self = shift;
  $self->{user_id} = shift if @_;
  return $self->{user_id};
}

sub created {
  my $self = shift;
  $self->{created} = shift if @_;
  return $self->{created};
}

sub get_disease_name {
  my $self = shift;
  my $lgm_panel_disease_adaptor = $self->{adaptor}->db->get_LGMPanelDiseaseAdaptor;
  my $lgm_panel_diseases = $lgm_panel_disease_adaptor->fetch_all_by_LGMPanel($self); 
  return $lgm_panel_diseases->[0]->get_Disease->name;
}

sub get_default_LGMPanelDisease {
  my $self = shift;
  my $lgm_panel_diseases = $self->get_all_LGMPanelDiseases;
  return $lgm_panel_diseases->[0]; 
}

sub get_all_LGMPanelDiseases {
  my $self = shift;
  my $lgm_panel_disease_adaptor = $self->{adaptor}->db->get_LGMPanelDiseaseAdaptor;
  return $lgm_panel_disease_adaptor->fetch_all_by_LGMPanel($self); 
}

1;
