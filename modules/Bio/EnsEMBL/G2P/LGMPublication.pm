=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2020] EMBL-European Bioinformatics Institute
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

package Bio::EnsEMBL::G2P::LGMPublication;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($LGM_publication_id, $locus_genotype_mechanism_id, $publication_id, $user_id, $created, $adaptor) =
    rearrange(['LGM_publication_id', 'locus_genotype_mechanism_id', 'publication_id', 'user_id', 'created', 'adaptor'], @_);

  my $self = bless {
    'dbID' => $LGM_publication_id,
    'LGM_publication_id' => $LGM_publication_id,
    'locus_genotype_mechanism_id' => $locus_genotype_mechanism_id,
    'publication_id' => $publication_id,
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

sub LGM_publication_id {
  my $self = shift;
  $self->{LGM_publication_id} = shift if @_;
  return $self->{LGM_publication_id};
}

sub locus_genotype_mechanism_id {
  my $self = shift;
  $self->{locus_genotype_mechanism_id} = shift if @_;
  return $self->{locus_genotype_mechanism_id};
}

sub publication_id {
  my $self = shift;
  $self->{publication_id} = shift if @_;
  return $self->{publication_id};
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

sub get_Publication {
  my $self = shift;
  my $publication_adaptor = $self->{adaptor}->db->get_PublicationAdaptor;
  return $publication_adaptor->fetch_by_dbID($self->publication_id);
}



1;
