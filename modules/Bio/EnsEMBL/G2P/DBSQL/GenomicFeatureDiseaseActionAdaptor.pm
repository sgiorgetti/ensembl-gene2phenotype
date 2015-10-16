use strict;
use warnings;

package Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseActionAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');


sub fetch_by_dbID {
  my $self = shift;
  my $dbID = shift;
  return $self->SUPER::fetch_by_dbID($dbID);
}

sub fetch_all_by_GenomicFeatureDisease {
  my $self = shift;
  my $genomic_feature_disease = shift;
  my $gfd_id = $genomic_feature_disease->dbID();
  my $constraint = "gfda.genomic_feature_disease_id=$gfd_id;";
  return $self->generic_fetch($constraint);
}


sub _columns {
  my $self = shift;
  my @cols = (
    'gfda.genomic_feature_disease_action_id',
    'gfda.genomic_feature_disease_id',
    'gfda.allelic_requirement_attrib',
    'gfda.mutation_consequence_attrib',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['genomic_feature_disease_action', 'gfda'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($genomic_feature_disease_action_id, $genomic_feature_disease_id, $allelic_requirement_attrib, $mutation_consequence_attrib);
  $sth->bind_columns(\($genomic_feature_disease_action_id, $genomic_feature_disease_id, $allelic_requirement_attrib, $mutation_consequence_attrib));

  my @objs;

  my $attribute_adaptor = $self->db->get_AttributeAdaptor;

  while ($sth->fetch()) {
    my $allelic_requirement = undef;
    my $mutation_consequence = undef;

    if ($allelic_requirement_attrib) {
      my @ids = split(',', $allelic_requirement_attrib);
      my @values = ();
      foreach my $id (@ids) {
        push @values, $attribute_adaptor->attrib_value_for_id($id);
      }
      $allelic_requirement = join(',', @values);
    }

    if ($mutation_consequence_attrib) {
      $mutation_consequence = $attribute_adaptor->attrib_value_for_id($mutation_consequence_attrib);
    }

    my $obj = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
      -genomic_feature_disease_action_id => $genomic_feature_disease_action_id, 
      -genomic_feature_disease_id => $genomic_feature_disease_id,
      -allelic_requirement_attrib => $allelic_requirement_attrib,
      -allelic_requirement => $allelic_requirement,
      -mutation_consequence_attrib => $mutation_consequence_attrib,
      -mutation_consequnece => $mutation_consequence,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
