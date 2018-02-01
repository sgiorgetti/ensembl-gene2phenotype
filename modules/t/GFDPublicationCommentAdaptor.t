=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute
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

my $gfdpca = $g2pdb->get_GFDPublicationCommentAdaptor;
my $gfdpa = $g2pdb->get_GenomicFeatureDiseasePublicationAdaptor;
my $ua = $g2pdb->get_UserAdaptor;

ok($gfdpca && $gfdpca->isa('Bio::EnsEMBL::G2P::DBSQL::GFDPublicationCommentAdaptor'), 'isa GFDPublicationCommentAdaptor');

my $gfdpc = $gfdpca->fetch_by_dbID(1);
ok($gfdpc->comment_text eq 'comment', 'comment text');

my $gfdp = $gfdpa->fetch_by_dbID(291);
my $gfdps = $gfdpca->fetch_all_by_GenomicFeatureDiseasePublication($gfdp);
ok(scalar @$gfdps == 1, 'fetch_all_by_GenomicFeatureDiseasePublication');

my $user = $ua->fetch_by_dbID(1);

my $GFD_publication_id = 503;
my $comment_text = 'test';

$gfdpc = Bio::EnsEMBL::G2P::GFDPublicationComment->new(
  -genomic_feature_disease_publication_id => $GFD_publication_id,
  -comment_text => $comment_text,
  -adaptor => $gfdpca,
);

ok($gfdpca->store($gfdpc, $user), 'store');

$gfdpc = $gfdpca->fetch_by_dbID($gfdpc->{GFD_publication_comment_id});

ok($gfdpc && $gfdpc->isa('Bio::EnsEMBL::G2P::GFDPublicationComment'), 'isa GFDPublicationComment');

ok($gfdpca->delete($gfdpc, $user), 'delete');

done_testing();
1;
