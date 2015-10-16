use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $da = $g2pdb->get_DiseaseAdaptor;

my $mim = '151210';
my $name = 'PLATYSPONDYLIC LETHAL SKELETAL DYSPLASIA TORRANCE TYPE (PLSD-T)';

my $gf = Bio::EnsEMBL::G2P::Disease->new(
  -mim => $mim,
  -name => $name,
  -adaptor => $da,
);

ok($gf->name eq $name, 'name');
ok($gf->mim eq $mim, 'mim');

done_testing();
1;


