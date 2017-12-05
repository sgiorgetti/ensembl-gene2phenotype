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
  'grch37' => 'http://grch37.rest.ensembl.org',
};

my $ext = '/vep/human/hgvs/';

#my $fh = FileHandle->new('/Users/anja/Documents/G2P/pubtator/20171128/results/matched_ensembl_hgvs2', 'r');
my $fh = FileHandle->new('/Users/anja/Documents/G2P/pubtator/20171128/results/gene_hgvs_pmid2', 'r');
my $fh_out = FileHandle->new('/Users/anja/Documents/G2P/pubtator/20171128/results/vep_results_ensembl_hgvs3', 'w');

my $pmids = {};
# allele_string assembly_name end id input most_severe_consequence regulatory_feature_consequences seq_region_name start strand transcript_consequences
# grch37  9887338 PCCA:c.5G>C hgvsc ENST00000424527.1:c.5G>C
while (<$fh>) {
  chomp;
  my ($hgvs, $pmid) = split/\t/;

  foreach my $server_version (keys %$servers) {
    my $server = $servers->{$server_version};
    my $response = $http->get($server.$ext.$hgvs, {
      headers => { 'Content-type' => 'application/json' }
    });
    if ($response->{success}) {
      if(length $response->{content}) {
        my $array = decode_json($response->{content});
        foreach my $hash (@$array) {
          my $assembly_name = $hash->{assembly_name};
          my $seq_region_name = $hash->{seq_region_name};
          my $start = $hash->{start};
          my $end = $hash->{end};
          my $strand = $hash->{strand};
          my $allele_string = $hash->{allele_string};
          my $most_severe_consequence = $hash->{most_severe_consequence};
          my $colocated_variants = '\N';
          if ($hash->{colocated_variants}) {
            $colocated_variants = join(',', map { $_->{id} } @{$hash->{colocated_variants}});
          }
          my $transcript_consequences = $hash->{transcript_consequences};
          #amino_acids biotype cdna_end cdna_start cds_end cds_start codons consequence_terms gene_id gene_symbol gene_symbol_source hgnc_id impact polyphen_prediction polyphen_score protein_end protein_start sift_prediction sift_score strand transcript_id variant_allele
          foreach my $tc (@$transcript_consequences) {
            my $transcript_id = $tc->{transcript_id};
            my $biotype = $tc->{biotype};
            my $gene_symbol = $tc->{gene_symbol};
            if (grep { $_ eq $most_severe_consequence } @{$tc->{consequence_terms}}) {
              my $consequence_terms = join(',', sort @{$tc->{consequence_terms}});
              my $sift_prediction = ($tc->{sift_prediction}) ? $tc->{sift_prediction} : '\N';
              my $polyphen_prediction = ($tc->{polyphen_prediction}) ? $tc->{polyphen_prediction} : '\N';
              print $fh_out join("\t", $pmid, $hgvs, $assembly_name, $seq_region_name, $start, $end, $strand, $allele_string, $most_severe_consequence, $colocated_variants, $gene_symbol, $transcript_id, $biotype, $consequence_terms, $sift_prediction, $polyphen_prediction), "\n";
            }
          }
          #          local $Data::Dumper::Terse = 1;
          #          local $Data::Dumper::Indent = 1;
          #          print Dumper $hash;
          #          print "\n";
        }
      } else {
      #      print $response->{content}, "\n";
      }
    }
  }
}


$fh->close;
$fh_out->close;
