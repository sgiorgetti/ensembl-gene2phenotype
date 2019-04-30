use strict;
use warnings;

use DBI;
use FileHandle;
use Getopt::Long;
use Bio::EnsEMBL::Registry;
my $config = {};

$config->{registry_file} = '/Users/anja/Documents/G2P/pubtator/20190426/ensembl.registry.apr2019';

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;

my $text_mining_disease_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'TextMiningDisease');
my $publication_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'Publication');
my $phenotype_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'Phenotype');


#my $pmid = 30269351;
#my $publication = $publication_adaptor->fetch_by_PMID($pmid);
#$text_mining_disease_adaptor->store_all_by_Publication($publication);

my $pmids = get_pmids_linked_to_GFDs();
print scalar keys %$pmids, "\n";
sub get_pmids_linked_to_GFDs {
  my $g2p_pmids = {};
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
  return $g2p_pmids;
}

