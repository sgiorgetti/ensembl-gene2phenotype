use strict;
use warnings;

use FileHandle;

my $pmids = {};

my $fh = FileHandle->new('/Users/anja/Documents/G2P/pubtator/20171128/results/ensembl_hgvs2', 'r');

my $fh_out = FileHandle->new('/Users/anja/Documents/G2P/pubtator/20171128/results/matched_ensembl_hgvs2', 'w');

while (<$fh>) {
  chomp;
#grch38 10051005  CA5A:c.3A>T hgvsc ENST00000309893.3:c.619-312A>T

  my ($assembly, $pmid, $pmid_hgvs, $hgvs_type, $ensembl_hgvs) = split/\t/;

  if (get_hgvs($pmid_hgvs) eq get_hgvs($ensembl_hgvs)) {
    $pmids->{$pmid} = 1;
    print $fh_out $_, "\n";
  }    
}


$fh->close;
$fh_out->close;

print scalar keys %$pmids, "\n";

sub get_hgvs {
  my $string = shift;
  my ($feature, $hgvs) = split(':', $string);
  return $hgvs;
}

