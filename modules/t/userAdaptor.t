use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $ua = $g2pdb->get_UserAdaptor;

ok($ua && $ua->isa('Bio::EnsEMBL::G2P::DBSQL::UserAdaptor'), 'isa user_adaptor');

my $dbID = 1;
my $username = 'user1';
my $email = 'user1@email.com';

my $user = $ua->fetch_by_dbID($dbID);
ok($user->dbID == $dbID, 'fetch_by_dbID');

$user = $ua->fetch_by_email($email);
ok($user->email eq $email, 'fetch_by_email');

$user = $ua->fetch_by_username($username);
ok($user->username eq $username, 'fetch_by_username');

done_testing();
1;
