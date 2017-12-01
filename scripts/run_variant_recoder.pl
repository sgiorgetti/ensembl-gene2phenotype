use strict;
use warnings;
 
use HTTP::Tiny;
use JSON;
use Data::Dumper;
use FileHandle;


my $http = HTTP::Tiny->new();

my $servers = {
  'grch38' => 'https://rest.ensembl.org',
  'grch37' => 'http://grch37.rest.ensembl.org',
};
 
my $ext = '/variant_recoder/human/';

my $fh = FileHandle->new('/Users/anja/Documents/G2P/pubtator/20171128/results/gene_hgvs_pmid2', 'r');
my $fh_out = FileHandle->new('/Users/anja/Documents/G2P/pubtator/20171128/results/ensembl_hgvs2', 'w');


while (<$fh>) {
  chomp;
  my ($hgvs, $pmid) = split/\t/;
  print "$hgvs\n";
  foreach my $server_version (keys %$servers) {
    my $server = $servers->{$server_version};
    my $response = $http->get($server.$ext.$hgvs, {
      headers => { 'Content-type' => 'application/json' }
    });
    if ($response->{success}) {
      if(length $response->{content}) {
        my $hash = decode_json($response->{content});
#warnings hgvsc hgvsp input hgvsg
        foreach my $hgvs_type (qw/hgvsc hgvsp hgvsg/) {
          if ($hash->[0]->{$hgvs_type}) {
            foreach my $string (@{$hash->[0]->{$hgvs_type}}) {
              print $fh_out join("\t", $server_version, $pmid, $hgvs, $hgvs_type, $string), "\n";
            }
          }
        }
#        local $Data::Dumper::Terse = 1;
#        local $Data::Dumper::Indent = 1;
#        print Dumper $hash;
#        print "\n";
      }
    } else {
#      print $response->{content}, "\n";
    }
  }
}

$fh->close;
$fh_out->close;

