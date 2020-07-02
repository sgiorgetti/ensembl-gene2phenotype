use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use DBI;
use Getopt::Long;
use FileHandle;

use Bio::EnsEMBL::G2P::AlleleFeature;
use Bio::EnsEMBL::G2P::TranscriptAllele;
use Bio::EnsEMBL::G2P::LocusGenotypeMechanism;

use Bio::SeqUtils;
use Bio::PrimarySeq;

my $config = {};

GetOptions(
  $config,
  'registry_file=s',
) or die "Error: Failed to parse command line arguments\n";

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);

my $species = 'human';
my $gene_feature_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GeneFeature');
my $locus_genotype_mechanism_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'LocusGenotypeMechanism');

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;
$dbh->do(qq{TRUNCATE TABLE locus_genotype_mechanism;}) or die $dbh->errstr;
my $gfda = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');

my $panel_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'Panel');
my $panels = $panel_adaptor->fetch_all;

foreach my $panel (sort {$a->name cmp $b->name} @$panels) {
  next if ($panel->name eq 'Demo');
  my $gfds = $gfda->fetch_all_by_panel($panel->name);

  foreach my $gfd (@$gfds) {
    my $gene = $gfd->get_GenomicFeature->gene_symbol;
    my $genomic_feature_id = $gfd->get_GenomicFeature->dbID;
    my $disease = $gfd->get_Disease->name;
    my $actions = $gfd->get_all_GenomicFeatureDiseaseActions; 
    foreach my $action (@$actions) { 
      my $allelic_requirement = $action->allelic_requirement || 'NA'; 
      my $mutation_consequence = $action->mutation_consequence || 'NA';
      print "$gene $allelic_requirement $mutation_consequence\n";
      my $locus_genotype_mechanism = $locus_genotype_mechanism_adaptor->fetch_by_locus_id_locus_type_genotype_mechanism($genomic_feature_id, 'gene', $allelic_requirement, $mutation_consequence);
      if (!defined  $locus_genotype_mechanism) {
        $locus_genotype_mechanism = Bio::EnsEMBL::G2P::LocusGenotypeMechanism->new(
          -adaptor => $locus_genotype_mechanism_adaptor,
          -locus_type => 'gene',
          -locus_id => $genomic_feature_id,
          -genotype => $allelic_requirement,
          -mechanism => $mutation_consequence,
        );
        $locus_genotype_mechanism_adaptor->store($locus_genotype_mechanism);
      }
    }
  }
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

  my $fh = FileHandle->new("/Users/anja/Documents/G2P/lgmd/entries_with_more_than_one_action_DD", 'w');

  foreach my $panel (@$panels) {
    my $name = $panel->name;
    next if ($name ne 'DD');
    my $gfds = $gfda->fetch_all_by_panel($name);
    print $fh $name, ' Entries: ', scalar @$gfds, "\n";
    foreach my $gfd (sort { $a->get_GenomicFeature->gene_symbol cmp $b->get_GenomicFeature->gene_symbol } @$gfds) {
      my $actions = $gfd->get_all_GenomicFeatureDiseaseActions; 
      if (scalar @$actions > 1) {
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
}
