=head1 LICENSE
 
See the NOTICE file distributed with this work for additional information
regarding copyright ownership.
 
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 
=cut
use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfdpca = $g2pdb->get_GFDPhenotypeCommentAdaptor;

my $GFD_phenotype_id = 2118;
my $comment_text = 'comment';
my $created = '2016-03-17 16:21:18';
my $user_id = 1;

my $gfdpc = Bio::EnsEMBL::G2P::GFDPhenotypeComment->new(
  -genomic_feature_disease_phenotype_id => $GFD_phenotype_id,
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
ok($phenotype->name eq 'Bulbous nose', 'phenotype name');

done_testing();
1;
