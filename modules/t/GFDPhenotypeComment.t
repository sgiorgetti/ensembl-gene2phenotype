use strict;

use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfdpca = $g2pdb->get_GFDPhenotypeCommentAdaptor;

my $GFD_phenotype_id = 3184;
my $comment_text = 'test';
my $created = '2015-10-09 17:03:57';
my $user_id = 1;

my $gfdpc = Bio::EnsEMBL::G2P::GFDPhenotypeComment->new(
  -GFD_phenotype_id => $GFD_phenotype_id,
  -comment_text => $comment_text,
  -created => $created,
  -user_id => $user_id,
  -adaptor => $gfdpca,
);

ok($gfdpc->GFD_phenotype_id == $GFD_phenotype_id, 'GFD_phenotype_id');
ok($gfdpc->comment_text eq $comment_text, 'comment_text');
ok($gfdpc->created eq $created, 'created');

my $user = $gfdpc->get_User();
ok($user->username eq 'user1', 'username');

my $gfdp = $gfdpc->get_GFD_phenotype();
my $phenotype = $gfdp->get_Phenotype();
ok($phenotype->name eq 'Cystic hygroma', 'phenotype name');

done_testing();
1;
