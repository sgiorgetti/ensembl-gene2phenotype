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

package Bio::EnsEMBL::G2P::Phenotype;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($phenotype_id, $stable_id, $name, $description, $adaptor) =
    rearrange(['phenotype_id', 'stable_id', 'name', 'description', 'adaptor'], @_);

  my $self = bless {
    'phenotype_id' => $phenotype_id,
    'stable_id' => $stable_id,
    'name' => $name,
    'description' => $description,
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  $self->{phenotype_id} = shift if @_;
  return $self->{phenotype_id};
}

sub stable_id {
  my $self = shift;
  $self->{stable_id} = shift if @_;
  return $self->{stable_id};
}

sub name {
  my $self = shift;
  $self->{name} = shift if @_;
  return $self->{name};
}

sub description {
  my $self = shift;
  $self->{description} = shift if @_;
  return $self->{description};
}


1;
