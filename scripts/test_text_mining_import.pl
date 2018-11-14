use strict;
use warnings;

use Bio::EnsEMBL::Registry;

my $registry_file = '/ensembl.registry.nov2018';
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all($registry_file);
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;

my $g2p_pmids = get_pmids_linked_to_GFDs();

my $text_mining_disease_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'TextMiningDisease');
my $publication_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'Publication');

foreach my $pmid (keys %$g2p_pmids) {
  my $publication = $publication_adaptor->fetch_by_PMID($pmid);
  print $publication->title, "\n";
  $text_mining_disease_adaptor->store_all_by_Publication_REST($publication);
}


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
