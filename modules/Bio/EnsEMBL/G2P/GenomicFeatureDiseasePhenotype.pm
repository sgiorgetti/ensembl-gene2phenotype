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

package Bio::EnsEMBL::G2P::GenomicFeatureDiseasePhenotype;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($GFD_phenotype_id, $genomic_feature_disease_id, $phenotype_id, $adaptor) =
    rearrange(['genomic_feature_disease_phenotype_id', 'genomic_feature_disease_id', 'phenotype_id', 'adaptor'], @_);

  my $self = bless {
    'genomic_feature_disease_phenotype_id' => $GFD_phenotype_id,
    'genomic_feature_disease_id' => $genomic_feature_disease_id,
    'phenotype_id' => $phenotype_id, 
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  $self->{genomic_feature_disease_phenotype_id} = shift if ( @_ );
  return $self->{genomic_feature_disease_phenotype_id};
}

sub genomic_feature_disease_id {
  my $self = shift;
  $self->{genomic_feature_disease_id} = shift if ( @_ );
  return $self->{genomic_feature_disease_id};
}

sub phenotype_id {
  my $self = shift;
  $self->{phenotype_id} = shift if ( @_ );
  return $self->{phenotype_id};
}

sub get_GenomicFeatureDisease {
  my $self = shift;
  my $genomic_feature_disease_adaptor = $self->{adaptor}->db->get_GenomicFeatureDiseaseAdaptor;
  return $genomic_feature_disease_adaptor->fetch_by_dbID($self->{genomic_feature_disease_id});
}

sub get_Phenotype {
  my $self = shift;
  my $phenotype_adaptor = $self->{adaptor}->db->get_PhenotypeAdaptor;
  return $phenotype_adaptor->fetch_by_dbID($self->{phenotype_id});
}

sub get_all_GFDPhenotypeComments {
  my $self = shift;
  my $GFD_phenotype_comment_adaptor = $self->{adaptor}->db->get_GFDPhenotypeCommentAdaptor;
  return $GFD_phenotype_comment_adaptor->fetch_all_by_GenomicFeatureDiseasePhenotype($self);
}

1;
