use strict;
use warnings;
 
use HTTP::Tiny;
use JSON;
use Data::Dumper;
use FileHandle;

my $http = HTTP::Tiny->new();

#  'grch37' => 'http://grch37.rest.ensembl.org',

my $servers = {
  'grch38' => 'https://rest.ensembl.org',
};
 
my $ext = '/variant_recoder/human/';

my $working_dir = '/Users/anja/Documents/G2P/lgmd/variants/';

my $fh = FileHandle->new("$working_dir/fgfr3.txt", 'r');
my $fh_out = FileHandle->new("$working_dir/fgfr3_hgvs_genomic.txt", 'w');

while (<$fh>) {
  chomp;
  my $hgvs = $_;
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
        foreach my $hgvs_type (qw/hgvsg/) {
          if ($hash->[0]->{$hgvs_type}) {
            foreach my $string (@{$hash->[0]->{$hgvs_type}}) {
              next if ($string =~ /^LRG/);
              print $fh_out join("\t", $string), "\n";
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

