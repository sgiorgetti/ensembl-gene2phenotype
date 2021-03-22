# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use FileHandle;
use DBI;
use Getopt::Long;
use Data::Dumper;
my $config = {};
GetOptions(
  $config,
  'registry_file=s',
  'panel=s',
  'output_file=s',
) or die "Error: Failed to parse command line arguments\n";
die ('A registry file is required (--registry_file)') unless (defined($config->{registry_file}));

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;
my $gfda = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');
my $GF_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeature');
my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');

my $panel = $config->{panel};
my $merge_list = $gfda->_get_all_duplicated_LGM_entries_by_panel($panel);
my $fh = FileHandle->new($config->{output_file}, 'w');
print $fh join("\t", qw/locus genotype-mechanism disease publication_list publication_count phenotype_list phenotype_count/), "\n";
foreach my $list (@{$merge_list}) {
  my $sets = get_sets($list);  
  for (my $i=0; $i < scalar(@{$sets}); $i++ ) {
    my $set_a = $sets->[$i];
    my $size_publication_a = scalar @{$set_a->{'publications'}};
    my $publication_list_a =  join(';', sort @{$set_a->{'publications'}});
    my $size_phenotype_a = scalar @{$set_a->{'phenotypes'}};
    my $phenotype_list_a =  join(';', sort  @{$set_a->{'phenotypes'}});
    my $gene_symbol = $set_a->{gene_symbol};
    my $actions = join(',', @{$set_a->{actions}});
      print $fh join("\t", $gene_symbol, $actions, $set_a->{'disease_name'}, $publication_list_a, $size_publication_a, $phenotype_list_a, $size_phenotype_a), "\n"; 
  }
}

$fh->close();
#{
#'mutation_consequence' => 'loss of function',
#'gf_id' => 60757,
#'gene_symbol' => 'LARGE1',
#'mutation_consequence_attrib' => '25',
#'allelic_requirement_attrib' => '3',
#'count' => 2,
#'genomic_feature_id' => 60757,
#'panel' => 'DD',
#'panel_id' => 38,
#'allelic_requirement' => 'biallelic'
#}

sub get_sets {
  my $list = shift;
  my $gf_id = $list->{gf_id};
  my $allelic_requirement_attrib = $list->{allelic_requirement_attrib};
  my $mutation_consequence_attrib = $list->{mutation_consequence_attrib};
  my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
  my $genotype = $attribute_adaptor->attrib_value_for_id($allelic_requirement_attrib);
  my $mechanism = $attribute_adaptor->attrib_value_for_id($mutation_consequence_attrib);

  my $genomic_feature = $GF_adaptor->fetch_by_dbID($gf_id);
  my $gene_symbol = $genomic_feature->gene_symbol;
  my $gfds = $gfda->fetch_all_by_GenomicFeature_panel($genomic_feature, $panel);

  my @entries = ();
  my @all_disease_names = ();

  my $phenotype_2_gfd_id = {};
  my $publication_2_gfd_id = {};

  my $gfd_id_2_disease_name = {};
  my $disease_name_2_gfd_id = {};

  foreach my $gfd (@$gfds) {
    
    next unless ($gfd->allelic_requirement_attrib eq $allelic_requirement_attrib && $gfd->mutation_consequence_attrib eq $mutation_consequence_attrib);

    my $gene_symbol = $gfd->get_GenomicFeature->gene_symbol;
    my $disease_name = $gfd->get_Disease->name;
    my $disease_id = $gfd->get_Disease->dbID;
    push @all_disease_names, [$disease_name => $disease_id];
    my $gfd_id = $gfd->dbID;

    $gfd_id_2_disease_name->{$gfd_id} = $disease_name;
    $disease_name_2_gfd_id->{$disease_name} = $gfd_id;

    my @actions = ();
    my $allelic_requirement = $gfd->allelic_requirement;
    my $mutation_consequence = $gfd->mutation_consequence;
    push @actions, "$allelic_requirement $mutation_consequence";

    my @publications = ();
    my $gfd_publications = $gfd->get_all_GFDPublications;
    foreach my $gfd_publication (@$gfd_publications) {
      my $publication =  $gfd_publication->get_Publication;
      my $title = $publication->title;
      if ($publication->source) {
        $title .= " " . $publication->source;
      }
      push @publications, $title;
      $publication_2_gfd_id->{$title}->{$gfd_id} = 1;
    }

    my @phenotypes = ();
    my $gfd_phenotypes = $gfd->get_all_GFDPhenotypes;
    foreach my $gfd_phenotype (@$gfd_phenotypes) {
      my $name = $gfd_phenotype->get_Phenotype->name;
      push @phenotypes, $name;
      $phenotype_2_gfd_id->{$name}->{$gfd_id} = 1;
    }

    push @entries, {
    gene_symbol => $gene_symbol,
    disease_name => $disease_name,
    gfd_id => $gfd_id,
    actions => \@actions,
    phenotypes => \@phenotypes,
    publications => \@publications,
    };
  }
  return \@entries;
}
