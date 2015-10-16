use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfdpca = $g2pdb->get_GFDPhenotypeCommentAdaptor;
my $gfdpa = $g2pdb->get_GenomicFeatureDiseasePhenotypeAdaptor;

ok($gfdpca && $gfdpca->isa('Bio::EnsEMBL::G2P::DBSQL::GFDPhenotypeCommentAdaptor'), 'isa GFDPhenotypeCommentAdaptor');

my $gfdpc = $gfdpca->fetch_by_dbID(9);
ok($gfdpc->comment_text eq 'test', 'comment text');

my $gfdp = $gfdpa->fetch_by_dbID(3184);
my $gfdps = $gfdpca->fetch_all_by_GenomicFeatureDiseasePhenotype($gfdp);
ok(scalar @$gfdps == 1, 'fetch_all_by_GenomicFeatureDiseasePhenotype');

done_testing();
1;
