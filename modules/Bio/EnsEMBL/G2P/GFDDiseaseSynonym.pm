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

package Bio::EnsEMBL::G2P::GFDDiseaseSynonym;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($gfd_disease_synonym_id, $genomic_feature_disease_id, $disease_id, $synonym, $adaptor) = rearrange(['gfd_disease_synonym_id', 'genomic_feature_disease_id', 'disease_id', 'synonym', 'adaptor'], @_); 

  my $self = bless {
    'GFD_disease_synonym_id' => $gfd_disease_synonym_id,
    'genomic_feature_disease_id' => $genomic_feature_disease_id,
    'disease_id' => $disease_id,
    'synonym' => $synonym,
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  $self->{GFD_disease_synonym_id} = shift if @_;
  return $self->{GFD_disease_synonym_id};
}

sub genomic_feature_disease_id {
  my $self = shift;
  $self->{'genomic_feature_disease_id'} = shift if ( @_);
  return $self->{'genomic_feature_disease_id'};
}

sub disease_id {
  my $self = shift;
  $self->{'disease_id'} = shift if ( @_);
  return $self->{'disease_id'};
}

sub synonym {
  my $self = shift;
  $self->{'synonym'} = shift if ( @_);
  return $self->{'synonym'};
}
1;
