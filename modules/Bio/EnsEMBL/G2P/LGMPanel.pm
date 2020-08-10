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

package Bio::EnsEMBL::G2P::LGMPanel;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($lgm_panel_id, $locus_genotype_mechanism_id, $panel_id, $confidence_category_id, $user_id, $created, $adaptor) =
    rearrange(['lgm_panel_id', 'locus_genotype_mechanism_id', 'panel_id', 'confidence_category_id', 'user_id', 'created', 'adaptor'], @_);

  my $self = bless {
    'dbID' => $lgm_panel_id,
    'lgm_panel_id' => $lgm_panel_id,
    'locus_genotype_mechanism_id' => $locus_genotype_mechanism_id,
    'panel_id' => $panel_id,
    'confidence_category_attrib' => $confidence_category_attrib,
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

sub lgm_panel_id {
  my $self = shift;
  $self->{lgm_panel_id} = shift if @_;
  return $self->{lgm_panel_id};
}

sub locus_genotype_mechanism_id {
  my $self = shift;
  $self->{locus_genotype_mechanism_id} = shift if @_;
  return $self->{locus_genotype_mechanism_id};
}

sub panel_id {
  my $self = shift;
  $self->{panel_id} = shift if @_;
  return $self->{panel_id};
}

sub confidence_category {
  my $self = shift;
  my $confidence_category = shift;
  my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;

  if ($confidence_category) {
    my $confidence_category_attrib = $attribute_adaptor->attrib_id_for_type_value('confidence_category', $value);
    $self->{confidence_category_attrib} = $confidence_category_attrib;
    $self->{confidence_category} = $confidence_category;
  } else {
    if (!$self->{confidence_category } && $self->{genotype_attrib} ) {
      my @ids = split(',', $self->{genotype_attrib});
      my @values = ();
      foreach my $id (@ids) {
        push @values, $attribute_adaptor->attrib_value_for_id($id);
      }
      $self->{genotype} = join(',', sort @values);
    }
  }
  return $self->{genotype};
}

sub confidence_category_attrib {
  my $self = shift;
  $self->{confidence_category_attrib} = shift if @_;
  return $self->{confidence_category_attrib};
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

1;
