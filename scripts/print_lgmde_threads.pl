use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use Data::Dumper;
use FileHandle;

my $registry_file = '/Users/anja/Documents/G2P/ensembl.registry.sep2020';
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all($registry_file);
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;


my $gfda = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');

my $panel_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'Panel');
my $panels = $panel_adaptor->fetch_all;

# locus-genotype-mechanism-disease-evidence
print_entries_with_more_than_one_action();

#create_lgmde_threads();
if (0) {
foreach my $panel (sort {$a->name cmp $b->name} @$panels) {
  my $gfds = $gfda->fetch_all_by_panel($panel->name);
  my $gene_disease_threads = scalar @$gfds;
  my ($unique_lgmd_threads, $duplicated_lgmd_threads, $more_than_one_action, $no_gm) = get_lgmd_threads($gfds);  
  my $total_lgmd_threads = $unique_lgmd_threads + $duplicated_lgmd_threads;
  print $panel->name, ' ', "$gene_disease_threads $total_lgmd_threads ($duplicated_lgmd_threads), $more_than_one_action, $no_gm\n";
}

my $all_gfds =  $gfda->fetch_all_by_panel('ALL');
my $gene_disease_threads = scalar @$all_gfds;
my ($unique_lgmd_threads, $duplicated_lgmd_threads, $more_than_one_action, $no_gm) = get_lgmd_threads($all_gfds);  
my $total_lgmd_threads = $unique_lgmd_threads + $duplicated_lgmd_threads;
print "ALL $gene_disease_threads $total_lgmd_threads ($duplicated_lgmd_threads), $more_than_one_action, $no_gm\n";
}


sub get_lgmd_threads {
  my $gfds = shift;
  my $threads = {};
  my $with_phenotype = 1;
  my $more_than_one_action = 0;
  my $no_gm = 0;

  foreach my $gfd (sort { $a->get_GenomicFeature->gene_symbol cmp $b->get_GenomicFeature->gene_symbol } @$gfds) {
    my $gene = $gfd->get_GenomicFeature->gene_symbol;
    my $disease = $gfd->get_Disease->name;
    my $actions = $gfd->get_all_GenomicFeatureDiseaseActions; 
    if (scalar @$actions > 1) {
      $more_than_one_action++;
    }
    foreach my $action (@$actions) { 
      my $allelic_requirement = $action->allelic_requirement || 'NA'; 
      my $mutation_consequence = $action->mutation_consequence || 'NA';
      my $key = join(' ', $gene, $allelic_requirement, $mutation_consequence);
      $threads->{$key}->{$disease}++;
    }
    if (scalar @$actions == 0) {
      $no_gm++;
      $threads->{"$gene\_$disease"}->{$disease}++;
    }

  }
  my $unique_threads = 0;
  my $duplicated_threads = 0;
  foreach my $thread (sort keys %$threads) {
    if (scalar keys %{$threads->{$thread}} > 1) {
      $duplicated_threads++;
    } else {
      $unique_threads++;
    }
  }
  return ($unique_threads, $duplicated_threads, $more_than_one_action, $no_gm);
}






sub print_entries_with_more_than_one_action {

  my $fh = FileHandle->new("/Users/anja/Documents/G2P/lgmd/entries_with_more_than_one_action_Ear_202009", 'w');
  my $count_duplicates = 0;
  foreach my $panel (@$panels) {
    my $name = $panel->name;
    next if ($name ne 'Ear');
    my $gfds = $gfda->fetch_all_by_panel($name);
    print $fh $name, ' Entries: ', scalar @$gfds, "\n";
    foreach my $gfd (sort { $a->get_GenomicFeature->gene_symbol cmp $b->get_GenomicFeature->gene_symbol } @$gfds) {
      my $actions = $gfd->get_all_GenomicFeatureDiseaseActions; 
      if (scalar @$actions > 1) {
        $count_duplicates++;
        my $gene = $gfd->get_GenomicFeature->gene_symbol;
        my $disease = $gfd->get_Disease->name;
        print $fh "    $gene $disease\n";
        foreach my $action (sort {$a->allelic_requirement cmp $b->allelic_requirement} @$actions) {
          my $allelic_requirement = $action->allelic_requirement; 
          my $mutation_consequence = $action->mutation_consequence;
            print $fh "        $allelic_requirement, $mutation_consequence\n";
        }
      }
    }
  }
  $fh->close;
  print $count_duplicates, "\n";
}
