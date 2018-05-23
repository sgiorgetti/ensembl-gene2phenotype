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

package Bio::EnsEMBL::G2P::GenomicFeatureDiseaseLog;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use base qw(Bio::EnsEMBL::G2P::GenomicFeatureDisease);

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;
  my ($created, $user_id, $action, $adaptor, $DDD_category, $gene_symbol, $disease_name, $genomic_feature_disease_id) =
    rearrange(['created', 'user_id', 'action', 'adaptor', 'DDD_category', 'gene_symbol', 'disease_name', 'genomic_feature_disease_id'], @_);
  my $self = $class->SUPER::new(@_);
 
  $self->{'created'} = $created;
  $self->{'user_id'} = $user_id;
  $self->{'action'} = $action;
  $self->{'adaptor'} = $adaptor;
  $self->{'DDD_category'} = $DDD_category;
  $self->{'gene_symbol'} = $gene_symbol;
  $self->{'disease_name'} = $disease_name;
  $self->{'genomic_feature_disease_id'} = $genomic_feature_disease_id;

  return $self;
}

sub genomic_feature_disease_id {
  my $self = shift;
  $self->{'genomic_feature_disease_id'} = shift if ( @_);
  return $self->{'genomic_feature_disease_id'};
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

sub gene_symbol {
  my $self = shift;
  $self->{gene_symbol} = shift if ( @_ );
  return $self->{gene_symbol};
}

sub disease_name {
  my $self = shift;
  $self->{disease_name} = shift if ( @_ );
  return $self->{disease_name};
}

sub disease_confidence {
  my $self = shift;
  my $DDD_category = shift;
  if ($DDD_category) {
    my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;
    my $DDD_category_attrib = $attribute_adaptor->attrib_id_for_value($DDD_category);
    die "Could not get DDD category attrib id for value $DDD_category\n" unless ($DDD_category_attrib);
    $self->{DDD_category} = $DDD_category;
    $self->{DDD_category_attrib} = $DDD_category_attrib;
  } else {
    if ($self->{DDD_category_attrib} && !$self->{DDD_category}) {
      my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;
      my $DDD_category = $attribute_adaptor->attrib_value_for_id($self->{DDD_category_attrib});
      $self->{DDD_category} = $DDD_category;
    }
#    die "No DDD_category" unless ($self->{DDD_category} );
  }
  return $self->{DDD_category};
}

1;
