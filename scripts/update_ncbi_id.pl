use strict;
use warnings;

use FileHandle;
use Bio::EnsEMBL::Registry;


my $registry_file = '/Users/anja/Documents/G2P/ensembl.registry.nov2017';
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all($registry_file);

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;




my $hgnc_id_2_ncbi_id_mappings = {};

my $fh = FileHandle->new('/Users/anja/Documents/G2P/data/hgnc_id_prev_symbol_ncbi_id_mappings_11_2017_mart.txt', 'r');

while (<$fh>) {
  chomp;
  next if (/^HGNC ID/);
  my ($hgnc_id, $approved_symbol, $prev_symbol, $ncbi_id) = split/\t/;
  $hgnc_id =~ s/HGNC://;
  if ($hgnc_id, $ncbi_id) {
    $dbh->do(qq{update genomic_feature set ncbi_id=$ncbi_id where hgnc_id=$hgnc_id;}) or die $dbh->errstr;    
    print $hgnc_id, ' ', $ncbi_id, "\n";
  }
}

$fh->close;

