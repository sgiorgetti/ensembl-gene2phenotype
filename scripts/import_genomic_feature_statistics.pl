use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use FileHandle;

my $registry_file = '/Users/anja/Documents/G2P/ensembl.registry.mar2019';
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all($registry_file);
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;


my $gfa = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeature');
my $gfsa = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureStatistic');

fetch();

sub fetch {

  my $genomic_features = $gfa->fetch_all;
  foreach my $gf (@$genomic_features) {
    my $gf_statistics = $gfsa->fetch_all_by_GenomicFeature($gf);
    if (scalar @$gf_statistics) {
      print $gf->gene_symbol, "\n";
      foreach my $gfs (@$gf_statistics) {
        print '    ', $gfs->dataset, ' ', $gfs->p_value, ' ', $gfs->clustering, "\n";
      }
    }
  }

}


sub import {
  my $fh = FileHandle->new('/Users/anja/Documents/G2P/genome_wide_significance.txt', 'r');

  while (<$fh>) {
    chomp;
    next if (/^Gene/); #Gene  Missense  PTV P-value Test  Clustering
    $_ =~ s/\R//g;
    my ($gene, $missense, $ptv, $p_value, $data_set, $clustering) = split/\t/;

    my $genomic_feature = $gfa->fetch_by_gene_symbol($gene) || $gfa->fetch_by_synonym($gene);
    if (!defined $genomic_feature) {
      print $gene, "\n";
      next;
    }
    my $is_clustered = $clustering eq 'Yes' ? 1 : 0; 
    my %attribs = ();
    $attribs{dataset} = $data_set; 
    $attribs{p_value} = $p_value; 
    $attribs{clustering} = $is_clustered; 

    my $genomic_feature_statistic = Bio::EnsEMBL::G2P::GenomicFeatureStatistic->new(
      -genomic_feature_id => $genomic_feature->dbID,
      -attribs => \%attribs, 
    );
    $gfsa->store($genomic_feature_statistic);
  }

  $fh->close;
}





