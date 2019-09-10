use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use Data::Dumper;
use FileHandle;
my $registry_file = '/Users/anja/Documents/G2P/pubtator/20190903/ensembl.registry.sep2019';
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all($registry_file);
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;

my $g2p_pmids = get_pmids_linked_to_GFDs();

my $text_mining_disease_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'TextMiningDisease');
my $gfda = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');

my $publication_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'Publication');
my $phenotype_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'Phenotype');


my $gfds = $gfda->fetch_all_by_panel('DD');
print scalar @$gfds, "\n";
my $count_big_overlap  = 0;


my $fh = FileHandle->new('phenotype_counts_text_mining_overlap.tsv', 'w');
print $fh "source\tphenotypes\n";
my $phenotype_annotations = {};
my $count = 1;
foreach my $gfd (@$gfds) {
  my $dbid = $gfd->dbID;
  my $gfd_publications = $gfd->get_all_GFDPublications;
  foreach my $gfd_publication (@$gfd_publications) {
    my $publication =  $gfd_publication->get_Publication;
    my $text_mining_diseases =  $text_mining_disease_adaptor->fetch_all_by_Publication($publication);
    foreach my $text_mining_disease (@$text_mining_diseases) {
      my $phenotype_id = $text_mining_disease->phenotype_id;      
      if ($phenotype_id) {
        my $phenotype = $phenotype_adaptor->fetch_by_dbID($phenotype_id);
        my $hpo_term = $phenotype->name;
#        print "text mining $hpo_term\n";
        $phenotype_annotations->{$dbid}->{text_mining}->{$hpo_term} = 1; 
      } 
    }
  }

  my $gfd_phenotypes = $gfd->get_all_GFDPhenotypes;
  foreach my $gfd_phenotype (@$gfd_phenotypes) {
    my $hpo_term = $gfd_phenotype->get_Phenotype->name;
#    print "annotated $hpo_term\n";

    $phenotype_annotations->{$dbid}->{annotated}->{$hpo_term} = 1; 
  }
  my $count_overlap = 0;
  foreach my $new_term (keys %{$phenotype_annotations->{$dbid}->{text_mining}}) {
    if (defined $phenotype_annotations->{$dbid}->{annotated}->{$new_term}) {
      $count_overlap++;
    }
  }

#  my $count_new = 0;
#  foreach my $new_term (keys %{$phenotype_annotations->{$dbid}->{text_mining}}) {
#    if (!defined $phenotype_annotations->{$dbid}->{annotated}->{$new_term}) {
#      $count_new++;
#    }
#  }
  my $already_existing = scalar keys %{$phenotype_annotations->{$dbid}->{annotated}};
#  $count_new = $count_new + $already_existing;
#  print $fh "without text mining\t$already_existing\n";
#  print $fh "overlap with text mining\t$count_overlap\n";
  if (!$count_overlap) {
    print $fh "overlap with text mining\t0\n";
  } else {
    my $percentage = $count_overlap/$already_existing;
    $count_big_overlap++ if ($percentage >= 0.5);

    print $fh "overlap with text mining\t$percentage\n";
  }
}
  print  $count_big_overlap, "\n";


$fh->close;
#foreach my $pmid (keys %$g2p_pmids) {
#  my $publication = $publication_adaptor->fetch_by_PMID($pmid);
#  print $publication->title, "\n";
#}


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


sub get_publication_counts_per_gfd {
  my $counts = {};
  my $sth = $dbh->prepare(q{
SELECT gfd.genomic_feature_disease_id, count(*) FROM genomic_feature_disease gfd
LEFT JOIN genomic_feature_disease_publication gfdp ON gfd.genomic_feature_disease_id = gfdp.genomic_feature_disease_id
WHERE gfd.panel_attrib=38
AND gfdp.genomic_feature_disease_id is not null
group by gfdp.genomic_feature_disease_id;
  }, {mysql_use_result => 1});

  $sth->execute() or die $dbh->errstr;
  my ($gfd_id, $publication_count);
  $sth->bind_columns(\($gfd_id, $publication_count));
  while ($sth->fetch) {
    $counts->{$publication_count}++;
  }
  $sth->finish;
  return $counts;
}

sub get_phenotype_counts_per_gfd {
  my $counts = {};
  my $sth = $dbh->prepare(q{SELECT gfd.genomic_feature_disease_id, count(*) FROM genomic_feature_disease gfd
LEFT JOIN genomic_feature_disease_phenotype gfdp ON gfd.genomic_feature_disease_id = gfdp.genomic_feature_disease_id
WHERE gfd.panel_attrib=38
AND gfdp.genomic_feature_disease_id is not null
group by gfdp.genomic_feature_disease_id;}, {mysql_use_result => 1});

}

