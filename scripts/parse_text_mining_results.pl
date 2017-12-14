use strict;
use warnings;

use FileHandle;
use Bio::EnsEMBL::Registry;


my $working_dir = '/hps/nobackup/production/ensembl/anja/G2P/text_mining/';
my $registry_file = "$working_dir/registry_file_live";
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all($registry_file);

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;


my $ncbi2genomic_feature_id = {};

my $sth = $dbh->prepare(q{
  SELECT genomic_feature_id, ncbi_id FROM genomic_feature where ncbi_id is not null;
}, {mysql_use_result => 1});
$sth->execute() or die $dbh->errstr;
my ($genomic_feature_id, $ncbi_id);
$sth->bind_columns(\($genomic_feature_id, $ncbi_id));
while ($sth->fetch) {
  $ncbi2genomic_feature_id->{$ncbi_id} = $genomic_feature_id;
}
# get all genomic feature
# get all publications


my $fh = FileHandle->new("$working_dir/data/gene2pubtator", 'r');

while (<$fh>) {
  chomp;
#PMID NCBI_Gene Mentions  Resource
  next if (/^PMID/);
  my ($pmid, $ncbi_gene, $mentions, $resource) = split/\t/;
  foreach my $gene (split(';', $ncbi_gene)) {
    my $gf_id = $ncbi2genomic_feature_id->{$gene};
    if ($gf_id) {
      $dbh->do(qq{INSERT INTO text_mining_pmid_gene(pmid, genomic_feature_id) values($pmid, $gf_id);}) or die $dbh->errstr;  
    }
  }
}

$fh->close;

