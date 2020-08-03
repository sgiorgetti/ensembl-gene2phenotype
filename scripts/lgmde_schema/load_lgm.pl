use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use DBI;
use Getopt::Long;
use FileHandle;
use Spreadsheet::Read;
use Bio::EnsEMBL::G2P::LocusGenotypeMechanism;
my $config = {};

GetOptions(
  $config,
  'registry_file=s',
  'import_file=s',
) or die "Error: Failed to parse command line arguments\n";


my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);

my $species = 'human';
my $g2p_panel = 'DD';
my $allele_feature_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'AlleleFeature');
my $transcript_allele_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'TranscriptAllele');
my $gene_feature_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GeneFeature');
my $locus_genotype_mechanism_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'LocusGenotypeMechanism');

my $gf_adaptor               = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeature');
my $disease_adaptor          = $registry->get_adaptor($species, 'gene2phenotype', 'Disease');
my $gfd_adaptor              = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDisease');
my $gfd_action_adaptor       = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseaseAction');
my $attrib_adaptor           = $registry->get_adaptor($species, 'gene2phenotype', 'Attribute');


my $panel_attrib_id = $attrib_adaptor->attrib_id_for_value($g2p_panel);

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;

my $file = $config->{import_file};
die "Data file $file doesn't exist" if (!-e $file);
my $book  = ReadData($file);
my $sheet = $book->[1];
my @rows = Spreadsheet::Read::rows($sheet);
foreach my $row (@rows) {
  my ($gene, $disease_name, $variant, $pmid) = @$row;

  my $variant_id = "$gene:$variant";
  my $allele_features = $allele_feature_adaptor->fetch_all_by_name($variant_id);
  print "allele_features " , scalar @{$allele_features}, "\n";

  next if ($gene =~ /^Gene/);
  my $gf = $gf_adaptor->fetch_by_gene_symbol($gene);
  my $disease_list = $disease_adaptor->fetch_all_by_name($disease_name);
  my @sorted_disease_list = sort {$a->dbID <=> $b->dbID} @$disease_list;
  my $disease = $sorted_disease_list[0]; 
  if ($gf && $disease) {
    my $gfd = $gfd_adaptor->fetch_by_GenomicFeature_Disease_panel_id($gf, $disease, $panel_attrib_id);
    my $gfd_actions = $gfd_action_adaptor->fetch_all_by_GenomicFeatureDisease($gfd);
    if (scalar @{$gfd_actions} == 1) {
      my $gfd_action = $gfd_actions->[0];
      my $allelic_requirement = $gfd_action->allelic_requirement || '';
      my $mutation_consequence = $gfd_action->mutation_consequence || '';
      foreach my $allele_feature (@{$allele_features}) {
        my $allele_feature_id = $allele_feature->dbID();
        my $locus_genotype_mechanism = $locus_genotype_mechanism_adaptor->fetch_by_locus_id_locus_type_genotype_mechanism($allele_feature_id, 'allele', $allelic_requirement, $mutation_consequence);
        if (!defined  $locus_genotype_mechanism) {
          $locus_genotype_mechanism = Bio::EnsEMBL::G2P::LocusGenotypeMechanism->new(
            -adaptor => $locus_genotype_mechanism_adaptor,
            -locus_type => 'allele',
            -locus_id => $allele_feature_id,
            -genotype => $allelic_requirement,
            -mechanism => $mutation_consequence,
          );
          $locus_genotype_mechanism_adaptor->store($locus_genotype_mechanism);
        }
      }
    }
  } else {
    print "$gene $disease_name\n";
  }
}



