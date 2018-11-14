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

package Bio::EnsEMBL::G2P::TextMiningDisease;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($text_mining_disease_id, $publication_id, $mesh_id, $annotated_text, $source, $phenotype_id, $mesh_stable_id, $mesh_name, $adaptor) = rearrange(['text_mining_disease_id', 'publication_id', 'mesh_id', 'annotated_text', 'source', 'phenotype_id', 'mesh_stable_id', 'mesh_name', 'adaptor'], @_);

  my $self = bless {
      'text_mining_disease_id' => $text_mining_disease_id,
      'publication_id' => $publication_id,
      'mesh_id' => $mesh_id,
      'annotated_text' => $annotated_text,
      'source' => $source,
      'phenotype_id' => $phenotype_id,
      'mesh_stable_id' => $mesh_stable_id,
      'mesh_name' => $mesh_name,
      'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub text_mining_disease_id {
  my $self = shift;
  $self->{text_mining_disease_id} = shift if ( @_ );
  return $self->{text_mining_disease_id};
}

sub publication_id {
  my $self = shift;
  $self->{publication_id} = shift if ( @_ );
  return $self->{publication_id};
}

sub phenotype_id {
  my $self = shift;
  $self->{phenotype_id} = shift if ( @_ );
  return $self->{phenotype_id};
}

sub mesh_id {
  my $self = shift;
  $self->{mesh_id} = shift if ( @_ );
  return $self->{mesh_id};
}

sub mesh_stable_id {
  my $self = shift;
  $self->{mesh_stable_id} = shift if ( @_ );
  return $self->{mesh_stable_id};
}

sub mesh_name {
  my $self = shift;
  $self->{mesh_name} = shift if ( @_ );
  return $self->{mesh_name};
}

sub annotated_text {
  my $self = shift;
  $self->{annotated_text} = shift if ( @_ );
  return $self->{annotated_text};
}

sub source {
  my $self = shift;
  $self->{source} = shift if ( @_ );
  return $self->{soruce};
}

sub add_phenotype_id {
  my $self = shift;
  my $phenotype_id = shift;
  $self->{'all_phenotype_ids'}{$phenotype_id}++;
  return;
}

sub get_all_phenotype_ids {
  my $self = shift;
  my @phenotype_ids = keys %{$self->{all_phenotype_ids}};
  return \@phenotype_ids;
}

1;
