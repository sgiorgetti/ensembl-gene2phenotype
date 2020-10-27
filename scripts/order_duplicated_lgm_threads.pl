use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use Data::Dumper;
use FileHandle;

my $registry_file = '/Users/anja/Documents/G2P/DDG2P/september/20200918/ensembl.registry.sep2020';

my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all($registry_file);
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;
my $gfda = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');
my $GF_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeature');
my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');

my $merge_list = $gfda->_get_all_duplicated_LGM_entries_by_panel('Eye');

my $fh = FileHandle->new('/Users/anja/Documents/G2P/order_duplicated_lgms_Eye.tsv', 'w');
print $fh join("\t", qw/locus genotype-mechanism disease_a disease_b publication_count_a publication_count_b publication_similarity phenotype_count_a phenotype_count_b phenotype_similarity/), "\n";
foreach my $list (@{$merge_list}) {
  my $sets = get_sets($list);  
  for (my $i=0; $i < scalar(@{$sets}); $i++ ) {
    for (my $j=$i+1; $j < scalar(@{$sets}); $j++) {
      my $set_a = $sets->[$i];
      my $set_b = $sets->[$j];
      next if ($set_a->{'disease_name'} eq $set_b->{'disease_name'});
      my $publication_similarity = similarity($set_a->{'publications'}, $set_b->{'publications'});
      my $phenotype_similarity = similarity($set_a->{'phenotypes'}, $set_b->{'phenotypes'});


      my $size_publication_a = scalar @{$set_a->{'publications'}}; 
      my $size_publication_b = scalar @{$set_b->{'publications'}};
      my $size_phenotype_a = scalar @{$set_a->{'phenotypes'}};
      my $size_phenotype_b = scalar @{$set_b->{'phenotypes'}};



      my $gene_symbol = $set_a->{gene_symbol};
      my $actions = join(',', @{$set_a->{actions}});
      print $fh join("\t", $gene_symbol, $actions, $set_a->{'disease_name'}, $set_b->{'disease_name'}, $size_publication_a, $size_publication_b, $publication_similarity, $size_phenotype_a, $size_phenotype_b, $phenotype_similarity), "\n"; 
    }
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


sub similarity {
  my ($set_a, $set_b) = @_;
  # A and B / A + B - A and B
  my $overlap = 0;
  foreach my $i (@{$set_a}) {
    if (grep $_ eq $i, @{$set_b}) {
      $overlap++;
    }
  }
  my $length_a = scalar @{$set_a};
  my $length_b = scalar @{$set_b};

  if ($length_a || $length_b) {
    my $similarity =  $overlap / (($length_a + $length_b ) - $overlap);
    return sprintf("%.6f", $similarity);
  }
  return 0;
}

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
  my $gfds = $gfda->fetch_all_by_GenomicFeature_panel($genomic_feature, 'DD');

  my @entries = ();
  my @all_disease_names = ();

  my $phenotype_2_gfd_id = {};
  my $publication_2_gfd_id = {};

  my $gfd_id_2_disease_name = {};
  my $disease_name_2_gfd_id = {};

  foreach my $gfd (@$gfds) {
    my $gfd_actions = $gfd->get_all_GenomicFeatureDiseaseActions;
    next unless (grep {$_->allelic_requirement_attrib == $allelic_requirement_attrib && $_->mutation_consequence_attrib == $mutation_consequence_attrib} @$gfd_actions);

    my $gene_symbol = $gfd->get_GenomicFeature->gene_symbol;
    my $disease_name = $gfd->get_Disease->name;
    my $disease_id = $gfd->get_Disease->dbID;
    push @all_disease_names, [$disease_name => $disease_id];
    my $gfd_id = $gfd->dbID;

    $gfd_id_2_disease_name->{$gfd_id} = $disease_name;
    $disease_name_2_gfd_id->{$disease_name} = $gfd_id;

    my @actions = ();
    foreach my $gfd_action (@$gfd_actions) {
      my $allelic_requirement = $gfd_action->allelic_requirement;
      my $mutation_consequence = $gfd_action->mutation_consequence;
      push @actions, "$allelic_requirement $mutation_consequence";
    }

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
