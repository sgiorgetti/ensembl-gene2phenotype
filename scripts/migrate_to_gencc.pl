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

use Bio::EnsEMBL::Registry;
use Getopt::Long;

use Data::Dumper;

my $config = {};
GetOptions(
  $config,
  'registry_file=s',
) or die "Error: Failed to parse command line arguments\n";

die ('A registry file is required (--registry_file)') unless (defined($config->{registry_file}));

# Instatiate registry object 
my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);
my $species = 'human';

my $mappings = {
  'original_allelic_requirement' => {
    'allelic_requirement' => {
      'biallelic' => 'biallelic_autosomal',
      'digenic' => 'digenic',
      'hemizygous' => 'monoallelic_X_hem',
      'imprinted' => 'imprinted',
      'mitochondrial' => 'mitochondrial',
      'monoallelic' => 'monoallelic_autosomal',
      'monoallelic (Y)' => 'monoallelic_Y_hem',
      'mosaic' => 'mosaic',
      'uncertain' => 'uncertain',
      'x-linked dominant' => 'monoallelic_X_het',
      'x-linked over-dominance' => 'monoallelic_X_het',
    },
    'cross_cutting_modifier' => {
      'mosaic' => 'typically mosaic',
      'x-linked over-dominance' => 'requires heterozygosity' 
    }
  },
  'original_mutation_consequence' => {
    'mutation_consequence' => {
      '5_prime or 3_prime UTR mutation' => '5_prime or 3_prime UTR mutation',
      'activating' => 'altered gene product structure',
      'all missense/in frame' => 'altered gene product structure',
      'cis-regulatory or promotor mutation' => 'cis-regulatory or promotor mutation',
      'dominant negative' => 'altered gene product structure',
      'gain of function' => 'altered gene product structure',
      'increased gene dosage' => 'increased gene product level',
      'loss of function' => 'absent gene product',
      'part of contiguous gene duplication' => 'increased gene product level',
      'part of contiguous genomic interval deletion' => 'absent gene product',
      'uncertain' => 'uncertain',
    },
    'mutation_consequence_flag' => {
      'activating' => 'restricted mutation set',
      'dominant negative' => 'restricted mutation set',
      'gain of function' => 'restricted mutation set',
      'part of contiguous gene duplication' => 'part of contiguous gene duplication',
      'part of contiguous genomic interval deletion' => 'part of contiguous genomic interval deletion',
    }
  },
  'original_confidence_category' => {
    'both RD and IF' => 'both RD and IF',
    'child IF' => 'child IF',
    'confirmed' => 'definitive',
    'possible' => 'limited',
    'probable' => 'strong'
  }
};

# genomic_feature_disease, genomic_feature_disease_deleted, genomic_feature_disease_log

my $attribute_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'Attribute');

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;

#update_gfd_like_table('genomic_feature_disease', 'genomic_feature_disease_id');
#update_gfd_like_table('genomic_feature_disease_deleted', 'genomic_feature_disease_id');
#update_gfd_like_table('genomic_feature_disease_log', 'genomic_feature_disease_log_id');

update_gfd_panel_like_table('genomic_feature_disease_panel', 'genomic_feature_disease_panel_id');
update_gfd_panel_like_table('genomic_feature_disease_panel_deleted', 'genomic_feature_disease_panel_id');
update_gfd_panel_like_table('genomic_feature_disease_panel_log', 'genomic_feature_disease_panel_log_id');


sub update_gfd_panel_like_table {
  my $table = shift;
  my $db_id_column_name = shift;

  my $sth = $dbh->prepare(qq{
    SELECT $db_id_column_name, original_confidence_category_attrib FROM $table;
  });
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my ($db_id, $original_confidence_category_attrib) = @{$row};
    $original_confidence_category_attrib ||= 33; 
    my $original_confience_category = $attribute_adaptor->get_value('original_confidence_category', $original_confidence_category_attrib);
    if (!$original_confience_category) {
      die "Could not map term $original_confidence_category_attrib\n";
    }

    # Confidence category
    my $confidence_category = $mappings->{'original_confidence_category'}->{$original_confience_category};  
    my $confidence_category_attrib = $attribute_adaptor->get_attrib('confidence_category', $confidence_category);

    print "UPDATE $table SET confidence_category_attrib =  $confidence_category_attrib WHERE $db_id_column_name = $db_id;\n";
  }
  $sth->finish();

}

sub update_gfd_like_table {
  my $table = shift;
  my $db_id_column_name = shift;

  my $sth = $dbh->prepare(qq{
    SELECT $db_id_column_name, original_allelic_requirement_attrib, original_mutation_consequence_attrib FROM $table;
  });
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my ($db_id, $original_allelic_requirement_attrib_id, $original_mutation_consequence_attrib_id) = @{$row};
    $original_allelic_requirement_attrib_id ||= '13';
    $original_mutation_consequence_attrib_id ||= '26';
    my $original_allelic_requirements = $attribute_adaptor->get_value('original_allelic_requirement', $original_allelic_requirement_attrib_id);
    my $original_mutation_consequence = $attribute_adaptor->get_value('original_mutation_consequence', $original_mutation_consequence_attrib_id);

    # Allelic requirement and cross cutting modifier
    my @allelic_requirements = ();
    my @cross_cutting_modifiers = ();
    foreach my $original_allelic_requirement (split/,/,  $original_allelic_requirements) {
      my $mapped_term = $mappings->{'original_allelic_requirement'}->{'allelic_requirement'}->{$original_allelic_requirement};
      die "$original_allelic_requirement could not be mapped to new term" if (! $mapped_term);
      push @allelic_requirements, $mappings->{'original_allelic_requirement'}->{'allelic_requirement'}->{$original_allelic_requirement};

      if (defined $mappings->{'original_allelic_requirement'}->{'cross_cutting_modifier'}->{$original_allelic_requirement}) {
        push @cross_cutting_modifiers, $mappings->{'original_allelic_requirement'}->{'cross_cutting_modifier'}->{$original_allelic_requirement};
      }

    }
    my $allelic_requirement = join(',', sort @allelic_requirements);
    my $cross_cutting_modifier = join(',', sort @cross_cutting_modifiers);

    # Mutation consequence
    my $mutation_consequence = $mappings->{'original_mutation_consequence'}->{'mutation_consequence'}->{$original_mutation_consequence};  

    # Mutation consequence flag
    my $mutation_consequence_flag = $mappings->{'original_mutation_consequence'}->{'mutation_consequence_flag'}->{$original_mutation_consequence};

    my @updates = ();
    my $allelic_requirement_attrib = $attribute_adaptor->get_attrib('allelic_requirement', $allelic_requirement);
    push @updates, "allelic_requirement_attrib = '$allelic_requirement_attrib'";

    my $mutation_consequence_attrib = $attribute_adaptor->get_attrib('mutation_consequence', $mutation_consequence);
    push @updates, "mutation_consequence_attrib = $mutation_consequence_attrib";
    
    if (defined $cross_cutting_modifier && $cross_cutting_modifier) {
      my $cross_cutting_modifier_attrib =  $attribute_adaptor->get_attrib('cross_cutting_modifier', $cross_cutting_modifier);
      push @updates, "cross_cutting_modifier_attrib = '$cross_cutting_modifier_attrib'";
    }

    if (defined $mutation_consequence_flag) {
      my $mutation_consequence_flag_attrib = $attribute_adaptor->get_attrib('mutation_consequence_flag', $mutation_consequence_flag);
      push @updates, "mutation_consequence_flag_attrib = '$mutation_consequence_flag_attrib'";
    }

    print "UPDATE $table SET ", join(", ", @updates), " WHERE $db_id_column_name = $db_id;\n";
  }
  $sth->finish();
}

