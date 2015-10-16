use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfa = $g2pdb->get_GenomicFeatureAdaptor;

ok($gfa && $gfa->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureAdaptor'), 'isa genomic_feature_adaptor');

my $dbID = 1252;
my $mim = '120140';
my $gene_symbol = 'COL2A1';
my $ensembl_stable_id = 'ENSG00000139219';

my $gfs = $gfa->fetch_all;
ok(scalar @$gfs == 1, 'fetch_all');

my $gf = $gfa->fetch_by_dbID($dbID);
ok($gf->dbID == $dbID, 'fetch_by_dbID');

$gf = $gfa->fetch_by_mim($mim);
ok($gf->mim eq $mim, 'fetch_by_mim');

$gf = $gfa->fetch_by_ensembl_stable_id($ensembl_stable_id);
ok($gf->ensembl_stable_id eq $ensembl_stable_id, 'fetch_by_ensembl_stable_id');

$gf = $gfa->fetch_by_gene_symbol($gene_symbol);
ok($gf->gene_symbol eq $gene_symbol, 'fetch_by_gene_symbol');

$gf = Bio::EnsEMBL::G2P::GenomicFeature->new(
  -mim => '610142',
  -gene_symbol => 'RAB27A',
  -ensembl_stable_id => 'ENSG00000069974',
);

ok($gfa->store($gf), 'store');

$gf = $gfa->fetch_by_gene_symbol('RAB27A');
ok($gf && $gf->gene_symbol eq 'RAB27A', 'fetch stored');

done_testing();
