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

package Bio::EnsEMBL::G2P::GenomicFeatureDiseaseAction;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($genomic_feature_disease_action_id, $genomic_feature_disease_id, $allelic_requirement_attrib, $allelic_requirement, $mutation_consequence_attrib, $mutation_consequence, $adaptor) =
    rearrange(['genomic_feature_disease_action_id', 'genomic_feature_disease_id', 'allelic_requirement_attrib', 'allelic_requirement', 'mutation_consequence_attrib', 'mutation_consequence' , 'ADAPTOR'], @_);

  my $self = bless {
    'dbID' => $genomic_feature_disease_action_id,
    'adaptor' => $adaptor,
    'genomic_feature_disease_action_id' => $genomic_feature_disease_action_id,
    'genomic_feature_disease_id' => $genomic_feature_disease_id,
    'allelic_requirement_attrib' => $allelic_requirement_attrib,
    'allelic_requirement' => $allelic_requirement,
    'mutation_consequence_attrib' => $mutation_consequence_attrib,
    'mutation_consequence' => $mutation_consequence,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  $self->{dbID} = shift if @_;
  return $self->{dbID};
}

sub genomic_feature_disease_id {
  my $self = shift;
  $self->{genomic_feature_disease_id} = shift if @_;
  return $self->{genomic_feature_disease_id};
}

sub allelic_requirement {
  my $self = shift;
  $self->{allelic_requirement} = shift if @_;
  
  if (!$self->{allelic_requirement} && $self->{allelic_requirement_attrib} ) {
    my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;
    my @ids = split(',', $self->{allelic_requirement_attrib});
    my @values = ();
    foreach my $id (@ids) {
      push @values, $attribute_adaptor->attrib_value_for_id($id);
    }
    $self->{allelic_requirement} = join(',', @values);
  }
  return $self->{allelic_requirement};
}

sub allelic_requirement_attrib {
  my $self = shift;
  $self->{allelic_requirement_attrib} = shift if @_;
  return $self->{allelic_requirement_attrib};
}

sub mutation_consequence {
  my $self = shift;
  $self->{mutation_consequence} = shift if @_;

  if (!$self->{mutation_consequence} && $self->{mutation_consequence_attrib}) {
    my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;
    $self->{mutation_consequence} = $attribute_adaptor->attrib_value_for_id($self->{mutation_consequence_attrib});
  }
  return $self->{mutation_consequence};
}

sub mutation_consequence_attrib {
  my $self = shift;
  $self->{mutation_consequence_attrib} = shift if @_;
  return $self->{mutation_consequence_attrib};
}

1;
