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

package Bio::EnsEMBL::G2P::Disease;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($disease_id, $mim, $name, $adaptor) =
    rearrange(['disease_id', 'mim', 'name', 'adaptor'], @_);

  my $self = bless {
    'dbID' => $disease_id,
    'adaptor' => $adaptor,
    'name' => $name,
    'mim' => $mim,
  }, $class;

  return $self;
}

sub new_fast {
  my $class = shift;
  my $hashref = shift;
  return bless $hashref, $class;
}

sub dbID {
  my $self = shift;
  $self->{dbID} = shift if ( @_ );
  return $self->{dbID};
}

sub name {
  my $self = shift;
  $self->{name} = shift if ( @_ );
  return $self->{name};
}

sub mim {
  my $self = shift;
  $self->{mim} = shift if ( @_ );
  return $self->{mim};
}

sub get_all_GenomicFeatureDiseases {
  my $self = shift;
  my $genomic_feature_disease_adaptor = $self->{adaptor}->db->get_GenomicFeatureDiseaseAdaptor;
  return $genomic_feature_disease_adaptor->fetch_all_by_disease_id($self->dbID);
}

sub get_all_Variations {
  my $self = shift;
  my $variation_adaptor = $self->{adaptor}->db->get_VariationAdaptor;
  return $variation_adaptor->fetch_all_by_disease_id($self->dbID);
}

sub ontology_accessions_with_source {
  my $self = shift;
  my $type = shift;

  return $self->{'_ontology_accessions'} unless $type;

  ## else filter ontology mappings by is/involves type
  my @accessions;
  foreach my $mapping (@{$self->{'_ontology_accessions'}}){
    next if defined $type && $mapping->{mapping_type} eq $type;
    push @accessions, $mapping;
  }
  return \@accessions;
}

sub ontology_accessions {
  my $self = shift;
  my $type = shift;

  my @accessions;
  foreach my $h (@{$self->{'_ontology_accessions'}}){
    next if defined $type && $type ne $h->{mapping_type};
    push @accessions, $h->{accession};
  }
  return \@accessions;
}

sub add_ontology_accession {
  my $self  = shift;
  my $data  = shift;
  throw('An accession must be supplied when updating')  unless $data->{accession};
  push @{$self->{'_ontology_accessions'}}, $data;
}


1;
