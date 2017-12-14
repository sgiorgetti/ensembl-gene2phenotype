use strict;
use warnings;

use FileHandle;
use HTTP::Tiny;
use JSON;
use Data::Dumper;
use FileHandle;

my $http = HTTP::Tiny->new();

my $servers = {
  'grch38' => 'https://rest.ensembl.org',
};
#  'grch37' => 'http://grch37.rest.ensembl.org',

my $server =  'https://rest.ensembl.org';
my $ext = '/vep/human/id/';

my $working_dir = '/hps/nobackup/production/ensembl/anja/G2P/text_mining/';

my $fh = FileHandle->new("$working_dir/results/gene_rsid_pmid_20171212", 'r');
my $fh_out = FileHandle->new("$working_dir/results/vep_results_ensembl_id_20171212", 'w');

my $pmids = {};
my $already_computed = {};
# allele_string assembly_name end id input most_severe_consequence regulatory_feature_consequences seq_region_name start strand transcript_consequences
# grch37  9887338 PCCA:c.5G>C hgvsc ENST00000424527.1:c.5G>C

while (<$fh>) {
  chomp;
  my ($pmid, $pmid_hgvs, $rsid, $type);
  $pmid_hgvs = 'No HGVS';

  if (/^rs/) {
    ($type, $rsid, $pmid) = split/\t/;
  } else {
  # hgvs  NF1:c.676C>T  9927033 rs63751615
    ($type, $pmid_hgvs, $pmid, $rsid) = split/\t/;
  }
  
  my $response = $http->get($server.$ext.$rsid."?hgvs=1&canonical=1", {
    headers => { 'Content-type' => 'application/json' }
  });
  if ($response->{success}) {
    if(length $response->{content}) {
      my $array = decode_json($response->{content});
      foreach my $hash (@$array) {
        my $assembly_name = $hash->{assembly_name};
        my $seq_region_name = $hash->{seq_region_name};
        next if ($seq_region_name !~ /^[0-9]+$|X|Y|MT/);
        my $start = $hash->{start};
        my $end = $hash->{end};
        my $strand = $hash->{strand};
#        my $allele_string = $hash->{allele_string};
        my @alleles = split('/', $hash->{allele_string});
        my $ref_allele = $alleles[0];
        my $most_severe_consequence = $hash->{most_severe_consequence};
        my $colocated_variants = '\N';
        if ($hash->{colocated_variants}) {
          $colocated_variants = join(',', map { $_->{id} } @{$hash->{colocated_variants}});
        }
        
        my $transcript_consequences = $hash->{transcript_consequences};
#amino_acids biotype cdna_end cdna_start cds_end cds_start codons consequence_terms gene_id gene_symbol gene_symbol_source hgnc_id impact polyphen_prediction polyphen_score protein_end protein_start sift_prediction sift_score strand transcript_id variant_allele
        foreach my $tc (@$transcript_consequences) {
          my $canonical = $tc->{canonical};
          next unless ($canonical);
          my $transcript_id = $tc->{transcript_id};
          my $biotype = $tc->{biotype};
          my $gene_symbol = $tc->{gene_symbol};
          my $gene_symbol_source = $tc->{gene_symbol_source};
          next if ($gene_symbol_source ne 'HGNC');
          my $variant_allele = $tc->{variant_allele};
          my $allele_string = "$ref_allele/$variant_allele";
          my $hgvsc = $tc->{hgvsc};
          
          if (grep { $_ eq $most_severe_consequence } @{$tc->{consequence_terms}}) {
            my $consequence_terms = join(',', sort @{$tc->{consequence_terms}});
            my $sift_prediction = ($tc->{sift_prediction}) ? $tc->{sift_prediction} : '\N';
            my $polyphen_prediction = ($tc->{polyphen_prediction}) ? $tc->{polyphen_prediction} : '\N';
            print $fh_out join("\t", $pmid, $rsid, $pmid_hgvs, $assembly_name, $seq_region_name, $start, $end, $strand, $allele_string, $most_severe_consequence, $colocated_variants, $gene_symbol, $transcript_id, $biotype, $consequence_terms, $sift_prediction, $polyphen_prediction), "\n";
          }
        }
      }
    }
  }
}

$fh->close;
$fh_out->close;
