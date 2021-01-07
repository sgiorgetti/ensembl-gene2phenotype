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

package Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($GFD_publication_id, $genomic_feature_disease_id, $publication_id, $adaptor) =
    rearrange(['genomic_feature_disease_publication_id', 'genomic_feature_disease_id', 'publication_id', 'adaptor'], @_);

  my $self = bless {
    'genomic_feature_disease_publication_id' => $GFD_publication_id,
    'genomic_feature_disease_id' => $genomic_feature_disease_id,
    'publication_id' => $publication_id,
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{genomic_feature_disease_publication_id};
}

sub get_GenomicFeatureDisease {
  my $self = shift;
  my $genomic_feature_disease_adaptor = $self->{adaptor}->db->get_GenomicFeatureDiseaseAdaptor;
  return $genomic_feature_disease_adaptor->fetch_by_dbID($self->{genomic_feature_disease_id});
}

sub get_Publication {
  my $self = shift;
  my $publication_adaptor = $self->{adaptor}->db->get_PublicationAdaptor;
  return $publication_adaptor->fetch_by_dbID($self->{publication_id});
}

sub get_all_GFDPublicationComments {
  my $self = shift;
  my $GFD_publication_comment_adaptor = $self->{adaptor}->db->get_GFDPublicationCommentAdaptor;
  return $GFD_publication_comment_adaptor->fetch_all_by_GenomicFeatureDiseasePublication($self);
}

1;
