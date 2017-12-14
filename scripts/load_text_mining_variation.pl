use strict;
use warnings;

use FileHandle;
use Bio::EnsEMBL::Registry;



my $working_dir = '/hps/nobackup/production/ensembl/anja/G2P/text_mining/';

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = "$working_dir/registry_file_live";
$registry->load_all($registry_file);

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;
my $gfa = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeature');
my $pa =  $registry->get_adaptor('human', 'gene2phenotype', 'Publication');

my $fh = FileHandle->new("$working_dir/results/filtered_vep_results_ensembl_hgvs_20171206", 'r');

my $pmid_2_publication_id = {};
my $gene_symbol_2_gf_id = {};

while (<$fh>) {
  chomp;
  my ($pmid, $pmid_hgvs, $hgvs_type, $ensembl_hgvs, $assembly_name, $seq_region_name, $start, $end, $strand, $allele_string, $most_severe_consequence, $colocated_variants, $gene_symbol, $transcript_id, $biotype, $consequence_terms, $sift_prediction, $polyphen_prediction) = split/\t/;

  my $genomic_feature_id = $gene_symbol_2_gf_id->{$gene_symbol};
  if (!$genomic_feature_id) {
    my $genomic_feature = $gfa->fetch_by_gene_symbol($gene_symbol);
    if ($genomic_feature) {
      $genomic_feature_id = $genomic_feature->dbID;
      $gene_symbol_2_gf_id->{$gene_symbol} = $genomic_feature_id;
    }
  }
  my $publication_id = $pmid_2_publication_id->{$pmid};
  if (!$publication_id) {
    my $publication = $pa->fetch_by_PMID($pmid);
    if ($publication) {
      $publication_id = $publication->dbID;
      $pmid_2_publication_id->{$pmid} = $publication_id;      
    }
  }
  if ($genomic_feature_id && $publication_id) {
    $polyphen_prediction = ($polyphen_prediction eq '\N') ? '\N' : "'$polyphen_prediction'";
    $sift_prediction = ($sift_prediction eq '\N') ? '\N' : "'$sift_prediction'";
    $colocated_variants = ($colocated_variants eq '\N') ? '\N' : "'$colocated_variants'";
    $dbh->do(qq{INSERT INTO text_mining_variation(publication_id, genomic_feature_id, text_mining_hgvs, ensembl_hgvs, assembly, seq_region, seq_region_start, seq_region_end, seq_region_strand, allele_string, consequence, feature_stable_id, biotype, polyphen_prediction, sift_prediction, colocated_variants)
              VALUES($publication_id, $genomic_feature_id, '$pmid_hgvs', '$ensembl_hgvs', '$assembly_name', '$seq_region_name', $start, $end, $strand, '$allele_string', '$consequence_terms', '$transcript_id', '$biotype', $sift_prediction, $polyphen_prediction, $colocated_variants); }) or die $dbh->errstr;

  }
}

$fh->close;
