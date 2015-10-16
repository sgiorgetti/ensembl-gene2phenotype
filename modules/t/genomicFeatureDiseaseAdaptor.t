use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfda = $g2pdb->get_GenomicFeatureDiseaseAdaptor;

ok($gfda && $gfda->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseAdaptor'), 'isa genomic_feature_disease_adaptor');

my $disease_id = 85;


#fetch_by_dbID
#fetch_by_GenomicFeature_Disease
#fetch_all_by_GenomicFeature
#fetch_all_by_GenomicFeature_panel
#fetch_all_by_Disease
#fetch_all_by_Disease_panel


my $gfds = $gfda->fetch_all_by_disease_id($disease_id);
ok(scalar @$gfds == 1, 'fetch_all_by_disease_id');



done_testing();
1;
