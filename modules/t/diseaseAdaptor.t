use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $da = $g2pdb->get_DiseaseAdaptor;

ok($da && $da->isa('Bio::EnsEMBL::G2P::DBSQL::DiseaseAdaptor'), 'isa disease_adaptor');

done_testing();
1;
