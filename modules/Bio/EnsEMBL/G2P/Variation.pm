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

package Bio::EnsEMBL::G2P::Disease;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($variation_id, $genomic_feature_id, $disease_id, $publication_id, $mutation, $consquence, $synonyms, $adaptor) =
    rearrange(['variation_id', 'genomic_feature_id', 'disease_id', 'publication_id', 'mutation', 'consequence', 'synonyms', 'adaptor'], @_);

  my $self = bless {
    'variation_id' => $variation_id,
    'genomic_feature_id' => $genomic_feature_id,
    'disease_id' => $disease_id,
    'publication_id' => $publication_id,
    'mutation' => $mutation,
    'consequence' => $consequence,
    'synonyms' => $synonyms, 
    'adaptor' => $adaptor, 
  }, $class;

  return $self;
}

sub variation_id {
  my $self = shift;
  $self->{variation_id} = shift if ( @_ );
  return $self->{variation_id};
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

sub mutation {
  my $self = shift;
  $self->{mutation} = shift if ( @_ );
  return $self->{mutation};
}

sub consequence {
  my $self = shift;
  $self->{consequence} = shift if ( @_ );
  return $self->{consequence};
}

sub publication_id {
  my $self = shift;
  $self->{publication_id} = shift if ( @_ );
  return $self->{publication_id};
}

sub get_all_synonyms_order_by_source {
  my $self = shift;
  my $variation_adaptor = $self->{adaptor};
  return $variation_adaptor->fetch_all_synonyms_order_by_source_by_variation_id($self->variation_id);
}

sub get_Publication {
  my $self = shift;
  unless ($self->publication_id) {
    return undef;
  }
  my $publication_adaptor = $self->{adaptor}->get_PublicationAdaptor;
  return $publication_adaptor->fetch_by_dbID($self->publication_id);
}

sub get_GenomicFeature {
  my $self = shift;
  my $genomic_feature_adaptor = $self->{adaptor}->get_GenomicFeatureAdaptor;
  return $genomic_feature_adaptor->fetch_by_dbID($self->genomic_feature_id);
}

1;
