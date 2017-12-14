use strict;
use warnings;

use FileHandle;
use Bio::EnsEMBL::Registry;


use FileHandle;
use HTTP::Tiny;
use JSON;
use Data::Dumper;
use FileHandle;

my $http = HTTP::Tiny->new();

my $servers = {
  'GRCh38' => 'https://rest.ensembl.org',
  'GRCh37' => 'http://grch37.rest.ensembl.org',
};

my $ext = '/lookup/id/';


my $working_dir = '/hps/nobackup/production/ensembl/anja/G2P/text_mining/';

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = "$working_dir/registry_file_live";
$registry->load_all($registry_file);

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;
my $gfa = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeature');
my $pa =  $registry->get_adaptor('human', 'gene2phenotype', 'Publication');


my $results = {};
my $canonical_transcripts = {};
my $transcripts = {};

my $fh = FileHandle->new("$working_dir/results/vep_results_ensembl_hgvs_20171206", 'r');
my $fh_out = FileHandle->new("$working_dir/results/filtered_vep_results_ensembl_hgvs_20171206", 'w');

my $pmid_2_publication_id = {};
my $gene_symbol_2_gf_id = {};
#9973283  GALE:p.Val94Met GRCh37  1 24124678  24124678  -1  G/A missense_variant  CM990624,rs121908047  GALE  ENST00000445705 protein_coding  missense_variant  deleterious probably_damaging
while (<$fh>) {
  chomp;
  my ($pmid, $pmid_hgvs, $hgvs_type, $ensembl_hgvs, $assembly_name, $seq_region_name, $start, $end, $strand, $allele_string, $most_severe_consequence, $colocated_variants, $gene_symbol, $transcript_id, $biotype, $consequence_terms, $sift_prediction, $polyphen_prediction) = split/\t/;

  $results->{$pmid_hgvs}->{$assembly_name}->{$gene_symbol}->{$transcript_id} = join("\t",  $consequence_terms, $sift_prediction, $polyphen_prediction);

  if (!$transcripts->{$assembly_name}->{$gene_symbol}->{$transcript_id}) {
    if (is_canonical($assembly_name, $transcript_id)) {
      $canonical_transcripts->{$assembly_name}->{$gene_symbol} = $transcript_id;
    }
    $transcripts->{$assembly_name}->{$gene_symbol}->{$transcript_id} = 1;
  }
}
$fh->close;

my $filtered_results = {};

foreach my $id (keys %$results) {
  foreach my $assembly (keys %{$results->{$id}}) {
    foreach my $gene_symbol (keys %{$results->{$id}->{$assembly}}) {
      my $canonical_transcript = $canonical_transcripts->{$assembly}->{$gene_symbol};
      my $attributes = 'NA';
      if ($canonical_transcript) {
        $attributes = $results->{$id}->{$assembly}->{$gene_symbol}->{$canonical_transcript} || 'NA';
      }
      if ($attributes ne 'NA') {
        $filtered_results->{$id}->{$assembly}->{$gene_symbol}->{$canonical_transcript} = 1;
        foreach my $transcript (keys %{$results->{$id}->{$assembly}->{$gene_symbol}}) {
          my $attributes2 = $results->{$id}->{$assembly}->{$gene_symbol}->{$transcript};
          if ($attributes2 ne $attributes) {
            $filtered_results->{$id}->{$assembly}->{$gene_symbol}->{$transcript} = 1;
          }
        }
      }
    }
  }
}

$fh = FileHandle->new("$working_dir/results/vep_results_ensembl_hgvs_20171206", 'r');

while (<$fh>) {
  chomp;
  my ($pmid, $pmid_hgvs, $hgvs_type, $ensembl_hgvs, $assembly, $seq_region_name, $start, $end, $strand, $allele_string, $most_severe_consequence, $colocated_variants, $gene_symbol, $transcript_id, $biotype, $consequence_terms, $sift_prediction, $polyphen_prediction) = split/\t/;
  if ($filtered_results->{$pmid_hgvs}->{$assembly}->{$gene_symbol}->{$transcript_id}) {
    print $fh_out $_, "\n";
  }
}

$fh->close;
$fh_out->close;


sub is_canonical {
  my ($assembly, $transcript_id) = @_;
  my $server = $servers->{$assembly};
  my $response = $http->get($server.$ext.$transcript_id, {
    headers => { 'Content-type' => 'application/json' }
  });
  if ($response->{success}) {
    my $hash = decode_json($response->{content});
    return $hash->{is_canonical};
  }
  return 0;
}
