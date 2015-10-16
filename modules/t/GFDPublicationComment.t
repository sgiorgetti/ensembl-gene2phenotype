use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfdpca = $g2pdb->get_GFDPublicationCommentAdaptor;

my $GFD_publication_id = 455;
my $comment_text = 'test';
my $created = '2015-10-09 17:04:23';
my $user_id = 1;

my $gfdpc = Bio::EnsEMBL::G2P::GFDPublicationComment->new(
  -GFD_publication_id => $GFD_publication_id,
  -comment_text => $comment_text,
  -created => $created,
  -user_id => $user_id,
  -adaptor => $gfdpca,
);

ok($gfdpc->GFD_publication_id == $GFD_publication_id, 'GFD_publication_id');
ok($gfdpc->comment_text eq $comment_text, 'comment_text');
ok($gfdpc->created eq $created, 'created');

my $user = $gfdpc->get_User();
ok($user->username eq 'user1', 'username');

my $gfdp = $gfdpc->get_GFD_publication();
my $publication = $gfdp->get_Publication();
ok($publication->title eq 'An amino acid substitution (Gly853-->Glu) in the collagen alpha 1(II) chain produces hypochondrogenesis.', 'publication title');

done_testing();
1;
