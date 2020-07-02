use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use DBI;
use Getopt::Long;
use FileHandle;

use Bio::EnsEMBL::G2P::AlleleFeature;
use Bio::EnsEMBL::G2P::TranscriptAllele;

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
my $allele_feature_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'AlleleFeature');
my $transcript_allele_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'TranscriptAllele');
my $gene_feature_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GeneFeature');

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;

$dbh->do(qq{TRUNCATE TABLE gene_feature;}) or die $dbh->errstr;
$dbh->do(qq{INSERT INTO gene_feature(gene_feature_id, gene_symbol, hgnc_id, mim, ensembl_stable_id) SELECT genomic_feature_id, gene_symbol, hgnc_id, mim, ensembl_stable_id FROM genomic_feature;}) or die $dbh->errstr;


my $hgvsg_to_input = {};

my $fh = FileHandle->new('/Users/anja/Documents/G2P/lgmd/variants/fgfr3_all_hgvs.txt', 'r');

while (<$fh>) {
  chomp;
  my ($assembly, $input, $hgvsg) = split(/\t/);
  $input =~ /(FGFR3\:p\.)([A-Za-z]*)([0-9]*)([A-Za-z]*)/;
  my $ref_aa = $2;
  my $pos = $3;
  my $alt_aa = $4;
  $hgvsg_to_input->{"$ref_aa-$pos-$alt_aa"} = $input;
}
$fh->close();

$fh = FileHandle->new('/Users/anja/Documents/G2P/lgmd/variants/vep_output.txt', 'r');
#Uploaded_variation Location  Allele  Consequence IMPACT  SYMBOL  Gene  Feature_type  Feature BIOTYPE EXON  INTRON  HGVSc HGVSp cDNA_position CDS_position  Protein_position  Amino_acids Codons  Existing_variation  DISTANCE  STRAND  FLAGS SYMBOL_SOURCE HGNC_ID MANE  TSL APPRIS  SIFT  PolyPhen  AF  CLIN_SIG  SOMATIC PHENO PUBMED  MOTIF_NAME  MOTIF_POS HIGH_INF_POS  MOTIF_SCORE_CHANGE
while (<$fh>) {
  next if (/^#/);
  chomp;
  my @values = split/\t/;
  my $uploaded_variant = $values[0];
  my $location = $values[1];
  my $protein_position = $values[16];
  my $amino_acids = $values[17];
  my $transcript_stable_id = $values[8];
  my $consequence_types = $values[3];
  my $cds_start = $values[15]; 
  my $cds_end = $values[15];
  my $cdna_start = $values[14]; 
  my $cdna_end = $values[14];
  my $translation_start = $values[16]; 
  my $translation_end = $values[16];
  my $codon_allele_string = $values[18];
  my $pep_allele_string = $values[17];
  my $gene = $values[5];
  print $gene, "\n";
  my $gene_feature = $gene_feature_adaptor->fetch_by_gene_symbol($gene);

  my ($ref_aa, $alt_aa) = split('/', $amino_acids);

  my $ref_aa_3_letters = Bio::SeqUtils->seq3(Bio::PrimarySeq->new(-seq => $ref_aa,  -alphabet => 'protein'));
  my $alt_aa_3_letters = Bio::SeqUtils->seq3(Bio::PrimarySeq->new(-seq => $alt_aa,  -alphabet => 'protein'));

  if ($hgvsg_to_input->{"$ref_aa_3_letters-$protein_position-$alt_aa_3_letters"}) {
    my $name = $hgvsg_to_input->{"$ref_aa_3_letters-$protein_position-$alt_aa_3_letters"};
    $location =~ /(\d+):(\d+)-(\d+)/;
    my $seq_region_name = $1;
    my $seq_region_start = $2;
    my $seq_region_end = $3;
    $uploaded_variant =~ /(.*\.\d+:g\.\d+)([A-Z]*)(>)([A-Z]*)/;
    my $ref_allele = $2;
    my $alt_allele = $4;
    my $hgvs_genomic = $uploaded_variant;
 
    my $allele_feature = $allele_feature_adaptor->fetch_by_name_and_hgvs_genomic($name, $hgvs_genomic);
    if (! defined $allele_feature) { 
      $allele_feature = Bio::EnsEMBL::G2P::AlleleFeature->new(
        -seq_region_name => $seq_region_name,
        -seq_region_start => $seq_region_start,
        -seq_region_end => $seq_region_end,
        -name => $name,
        -ref_allele => $ref_allele,
        -alt_allele => $alt_allele,
        -hgvs_genomic => $hgvs_genomic,
        -adaptor => $allele_feature_adaptor,
      );
      $allele_feature_adaptor->store($allele_feature);
    }
    my $allele_feature_id = $allele_feature->dbID;
    my $transcript_allele = $transcript_allele_adaptor->fetch_by_allele_feature_id_and_transcript_stable_id($allele_feature_id, $transcript_stable_id);
    if (! defined $transcript_allele) {
      $transcript_allele = Bio::EnsEMBL::G2P::TranscriptAllele->new(
        -allele_feature_id => $allele_feature_id,
        -transcript_stable_id => $transcript_stable_id,
        -gene_feature_id => $gene_feature->dbID,
        -consequence_types => $consequence_types,
        -cds_start => $cds_start,
        -cds_end => $cds_end,
        -cdna_start => $cdna_start,
        -cdna_end => $cdna_end,
        -translation_start => $translation_start,
        -translation_end => $translation_end,
        -codon_allele_string => $codon_allele_string,
        -pep_allele_string => $pep_allele_string,
        -adaptor => $transcript_allele_adaptor,
      );
      $transcript_allele_adaptor->store($transcript_allele);
    }
  }
}
$fh->close();
