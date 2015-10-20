=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

package Bio::EnsEMBL::G2P::GenomicFeatureDisease;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($genomic_feature_disease_id, $genomic_feature_id, $disease_id, $DDD_category, $DDD_category_attrib, $is_visible, $panel, $panel_attrib, $adaptor) =
    rearrange(['genomic_feature_disease_id', 'genomic_feature_id', 'disease_id', 'DDD_category', 'DDD_category_attrib', 'is_visible', 'panel', 'panel_attrib', 'adaptor'], @_);

  my $self = bless {
    'dbID' => $genomic_feature_disease_id,
    'adaptor' => $adaptor,
    'genomic_feature_disease_id' => $genomic_feature_disease_id,
    'genomic_feature_id' => $genomic_feature_id,
    'disease_id' => $disease_id,
    'DDD_category' => $DDD_category,
    'DDD_category_attrib' => $DDD_category_attrib,
    'is_visible' => $is_visible,
    'panel' => $panel,
    'panel_attrib' => $panel_attrib,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  $self->{genomic_feature_disease_id} = shift if ( @_ );
  return $self->{genomic_feature_disease_id};
}

sub genomic_feature_id {
  my $self = shift;
  $self->{genomic_feature_id} = shift if ( @_ );
  return $self->{genomic_feature_id};
}

sub disease_id {
  my $self = shift;
  $self->{disease_id} = shift if ( @_ );
  return $self->{disease_id};
}

sub DDD_category {
  my $self = shift;
  my $DDD_category = shift;
  my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;
  if ($DDD_category) {
    $self->{DDD_category} = $DDD_category;
    my $DDD_category_attrib = $attribute_adaptor->attrib_id_for_value($DDD_category);
    $self->DDD_category_attrib($DDD_category_attrib);
  } else {
    if (!$self->{DDD_category} && $self->{DDD_category_attrib}) {
      $self->{DDD_category} = $attribute_adaptor->attrib_value_for_id($self->{DDD_category_attrib});
    }
  }
  return $self->{DDD_category};
}

sub DDD_category_attrib {
  my $self = shift;
  $self->{DDD_category_attrib} = shift if ( @_ );
  return $self->{DDD_category_attrib};
}

sub is_visible {
  my $self = shift;
  $self->{is_visible} = shift if ( @_ );
  return $self->{is_visible};
}

sub panel {
  my $self = shift;
  $self->{panel} = shift if ( @_ );
  return $self->{panel};
}

sub panel_attrib {
  my $self = shift;
  $self->{panel_attrib} = shift if ( @_ );
  return $self->{panel_attrib};
}

sub get_all_GenomicFeatureDiseaseActions {
  my $self = shift;
  my $GFDA_adaptor = $self->{adaptor}->db->get_GenomicFeatureDiseaseActionAdaptor;
  return $GFDA_adaptor->fetch_all_by_GenomicFeatureDisease($self);       
}

sub get_GenomicFeature {
  my $self = shift;
  my $GF_adaptor = $self->{adaptor}->db->get_GenomicFeatureAdaptor;
  return $GF_adaptor->fetch_by_dbID($self->genomic_feature_id);
}

sub get_Disease {
  my $self = shift;
  my $disease_adaptor = $self->{adaptor}->db->get_DiseaseAdaptor;
  return $disease_adaptor->fetch_by_dbID($self->disease_id);
}

sub get_all_Variations {
  my $self = shift;
}

sub get_all_GFDPublications {
  my $self = shift;
}

sub get_all_GFDPhenotypes {
  my $self = shift;
}

sub get_all_GFDOrgans {
  my $self = shift;
}

1;
