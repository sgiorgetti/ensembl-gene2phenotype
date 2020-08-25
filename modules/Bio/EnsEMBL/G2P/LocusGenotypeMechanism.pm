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

package Bio::EnsEMBL::G2P::LocusGenotypeMechanism;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($locus_genotype_mechanism_id, $locus_type, $locus_id, $genotype_attrib, $genotype, $mechanism_attrib, $mechanism, $adaptor) =
    rearrange(['locus_genotype_mechanism_id', 'locus_type', 'locus_id', 'genotype_attrib', 'genotype', 'mechanism_attrib', 'mechanism', 'adaptor'], @_);

  my $self = bless {
    'dbID' => $locus_genotype_mechanism_id,
    'locus_genotype_mechanism_id' => $locus_genotype_mechanism_id,
    'adaptor' => $adaptor,
    'locus_type' => $locus_type,
    'locus_id' => $locus_id, 
    'genotype_attrib' => $genotype_attrib,
    'genotype' => $genotype,
    'mechanism_attrib' => $mechanism_attrib,
    'mechanism' => $mechanism,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  $self->{dbID} = shift if @_;
  return $self->{dbID};
}

sub locus_type {
  my $self = shift;
  $self->{locus_type} = shift if @_;
  return $self->{locus_type};
}

sub locus_id {
  my $self = shift;
  $self->{locus_id} = shift if @_;
  return $self->{locus_id};
}

sub genotype {
  my $self = shift;
  my $genotype = shift;
  my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;

  if ($genotype) {
    my @values = split(',', $genotype); 
    my @ids = ();
    foreach my $value (@values) {
      push @ids, $attribute_adaptor->attrib_id_for_type_value('allelic_requirement', $value);
    }        
    $self->{genotype_attrib} = join(',', sort @ids);
    $self->{genotype} = $genotype;
  } else {
    if (!$self->{genotype} && $self->{genotype_attrib} ) {
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

sub genotype_attrib {
  my $self = shift;
  $self->{genotype_attrib} = shift if @_;
  return $self->{genotype_attrib};
}

sub mechanism {
  my $self = shift;
  my $mechanism = shift;
  my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;
  if ($mechanism) {
    $self->{mechanism_attrib} = $attribute_adaptor->attrib_id_for_type_value('mutation_consequence', $mechanism);
    $self->{mechanism} = $mechanism;
  } else { 
    if (!$self->{mechanism} && $self->{mechanism_attrib}) {
      $self->{mechanism} = $attribute_adaptor->attrib_value_for_id($self->{mechanism_attrib});
    }
  }
  return $self->{mechanism};
}

sub mechanism_attrib {
  my $self = shift;
  $self->{mechanism_attrib} = shift if @_;
  return $self->{mechanism_attrib};
}


sub get_AlleleFeature {
  my $self = shift;
  my $allele_feature_adaptor = $self->{adaptor}->db->get_AlleleFeatureAdaptor;
  return $allele_feature_adaptor->fetch_by_dbID($self->locus_id);
}

sub get_GeneFeature {
  my $self = shift;
  my $gene_feature_adaptor = $self->{adaptor}->db->get_GeneFeatureAdaptor;
  return $gene_feature_adaptor->fetch_by_dbID($self->locus_id);
}

sub get_all_LGMPanels{
  my $self = shift;
  my $lgm_panel_adaptor = $self->{adaptor}->db->get_LGMPanelAdaptor;
  return $lgm_panel_adaptor->fetch_all_by_LocusGenotypeMechanism($self);
}

sub get_all_LGMPublications {
  my $self = shift;
  my $lgm_publication_adaptor = $self->{adaptor}->db->get_LGMPublicationAdaptor;
  return $lgm_publication_adaptor->fetch_all_by_LocusGenotypeMechanism($self); 
}


1;
