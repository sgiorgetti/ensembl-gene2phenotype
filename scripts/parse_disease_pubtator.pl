use strict;
use warnings;

use FileHandle;
use Bio::EnsEMBL::Registry;
use Array::Utils qw(:all);
my $working_dir = '/hps/nobackup/production/ensembl/anja/G2P/text_mining/';
my $registry_file = "$working_dir/registry_file_live";
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all($registry_file);
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;

my $g2p_pmids = {};
my $g2p_pmid_2_gene_symbol = {};


my $sth = $dbh->prepare(q{
  SELECT distinct p.pmid, p.publication_id from genomic_feature_disease_publication gfdp, publication p WHERE gfdp.publication_id = p.publication_id;
}, {mysql_use_result => 1});
$sth->execute() or die $dbh->errstr;
my ($pmid, $publication_id);
$sth->bind_columns(\($pmid, $publication_id));
while ($sth->fetch) {
  $g2p_pmids->{$pmid} = $publication_id;
}
$sth->finish;

print scalar keys %$g2p_pmids, "\n";

$sth = $dbh->prepare(q{SELECT distinct pg.pmid, gf.gene_symbol from genomic_feature_disease_publication gfdp, text_mining_pmid_gene pg, genomic_feature gf where gfdp.publication_id = pg.publication_id and pg.genomic_feature_id = gf.genomic_feature_id}, {mysql_use_result => 1});
$sth->execute() or die $dbh->errstr;
my ($gene_symbol);
$sth->bind_columns(\($pmid, $gene_symbol));
while ($sth->fetch) {
  $g2p_pmid_2_gene_symbol->{$pmid}->{$gene_symbol} = 1;
}
$sth->finish;

print scalar keys %$g2p_pmid_2_gene_symbol, "\n";


my $fh_out = FileHandle->new("$working_dir/results/meshIDs_20171214", 'w');

my $fh = FileHandle->new("$working_dir/data/disease2pubtator", 'r');

my $meshIDs = {};


my $meshids = {};

while (<$fh>) {
  chomp;
  next if (/^PMID/);
#PMID    MeshID  Mentions        Resource
  my ($pmid, $meshID, $mentions, $resource) = split/\t/;
  next if (!$g2p_pmids->{$pmid});

  $meshIDs->{$meshID} = 1;

}

$fh->close;

foreach my $meshID (keys %$meshIDs) {
  print $fh_out "$meshID\n";
}

$fh_out->close;
