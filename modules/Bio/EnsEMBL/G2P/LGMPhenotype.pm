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

package Bio::EnsEMBL::G2P::LGMPhenotype;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($LGM_phenotype_id, $locus_genotype_mechanism_id, $phenotype_id, $user_id, $created, $adaptor) =
    rearrange(['LGM_phenotype_id', 'locus_genotype_mechanism_id', 'phenotype_id', 'user_id', 'created', 'adaptor'], @_);

  my $self = bless {
    'dbID' => $LGM_phenotype_id,
    'LGM_phenotype_id' => $LGM_phenotype_id,
    'locus_genotype_mechanism_id' => $locus_genotype_mechanism_id,
    'phenotype_id' => $phenotype_id,
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

sub LGM_phenotype_id {
  my $self = shift;
  $self->{LGM_phenotype_id} = shift if @_;
  return $self->{LGM_phenotype_id};
}

sub locus_genotype_mechanism_id {
  my $self = shift;
  $self->{locus_genotype_mechanism_id} = shift if @_;
  return $self->{locus_genotype_mechanism_id};
}

sub phenotype_id {
  my $self = shift;
  $self->{phenotype_id} = shift if @_;
  return $self->{phenotype_id};
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

sub get_Phenotype {
  my $self = shift;
  my $phenotype_adaptor = $self->{adaptor}->db->get_PhenotypeAdaptor;
  return $phenotype_adaptor->fetch_by_dbID($self->phenotype_id);
}

sub get_User {
  my $self = shift;
  my $user_adaptor = $self->{adaptor}->db->get_UserAdaptor;
  return $user_adaptor->fetch_by_dbID($self->user_id);
}

1;
