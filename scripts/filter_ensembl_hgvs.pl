use strict;
use warnings;

use FileHandle;

my $pmids = {};

my $working_dir = '/hps/nobackup/production/ensembl/anja/G2P/text_mining/';

my $fh = FileHandle->new("$working_dir/results/ensembl_hgvs_20171206", 'r');

my $fh_out = FileHandle->new("$working_dir/results/matched_ensembl_hgvs_20171206", 'w');

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

