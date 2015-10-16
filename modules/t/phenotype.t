use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $pa = $g2pdb->get_PhenotypeAdaptor;

my $stable_id = 'HP:0000006';
my $name = 'Autosomal dominant inheritance';
my $description = undef;

my $phenotype = Bio::EnsEMBL::G2P::Phenotype->new(
  -stable_id => $stable_id,
  -name => $name,
  -description => $description,
  -adaptor => $pa,
);

ok($phenotype->stable_id eq $stable_id, 'stable_id');
ok($phenotype->name eq $name, 'name');
ok(!(defined $phenotype->description), 'description');

done_testing();
1;
