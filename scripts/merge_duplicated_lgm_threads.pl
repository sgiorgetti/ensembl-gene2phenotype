use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use Data::Dumper;
use FileHandle;

my $registry_file = '/Users/anja/Documents/G2P/DDG2P/october/merge/ensembl.registry.oct2020';

my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all($registry_file);
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;
my $gfda = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');
my $GF_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeature');
my $GFD_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');
my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');

my $merge_list = $gfda->_get_all_duplicated_LGM_entries_by_panel('DD');
my $user = $user_adaptor->fetch_by_username('anja_thormann');
foreach my $list (@{$merge_list}) {
  if ($list->{'allelic_requirement'} eq 'biallelic' && $list->{'mutation_consequence'} eq 'loss of function') {
    my @gfd_ids = ();
    my $gf_id;
    my $disease_id;
    my $sets = get_sets($list);  
    foreach my $set (@$sets) {
      push @gfd_ids, $set->{gfd_id};
      $gf_id = $set->{gf_id};
      $disease_id = $set->{disease_id};
    }
    my $gfd = $GFD_adaptor->_merge_all_duplicated_LGM_by_panel_gene($user, $gf_id, $disease_id, 'DD', \@gfd_ids);
  }
}


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
  my $gfds = $gfda->fetch_all_by_GenomicFeature_panel($genomic_feature, 'DD');

  my @entries = ();

  foreach my $gfd (@$gfds) {
    my $gfd_actions = $gfd->get_all_GenomicFeatureDiseaseActions;
    next if (scalar @$gfd_actions != 1);
    next unless (grep {$_->allelic_requirement_attrib == $allelic_requirement_attrib && $_->mutation_consequence_attrib == $mutation_consequence_attrib} @$gfd_actions);

    my $gf_id = $gfd->get_GenomicFeature->dbID;
    my $disease_id = $gfd->get_Disease->dbID;
    my $gfd_id = $gfd->dbID;

    push @entries, {
    disease_id => $disease_id,
    gf_id => $gf_id,
    gfd_id => $gfd_id,
    };
  }
  return \@entries;
}
