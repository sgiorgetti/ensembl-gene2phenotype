=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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
use Test::Exception;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfda = $g2pdb->get_GenomicFeatureDiseaseAdaptor;
my $da = $g2pdb->get_DiseaseAdaptor;
my $gfa = $g2pdb->get_GenomicFeatureAdaptor;
my $ua = $g2pdb->get_UserAdaptor;

ok($gfda && $gfda->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseAdaptor'), 'isa GenomicFeatureDiseaseAdaptor');

# store and update
my $disease_name = 'KABUKI SYNDROME (KABS)';
my $disease = $da->fetch_by_name($disease_name);
ok($disease->name eq $disease_name, 'disease object');
my $gene_symbol = 'P3H1';
my $genomic_feature = $gfa->fetch_by_gene_symbol($gene_symbol); 
ok($genomic_feature->gene_symbol eq $gene_symbol, 'genomic_feature object');
my $username = 'user1';
my $user = $ua->fetch_by_username($username);
ok($user->username eq $username, 'user object');

my $DDD_category = 'both DD and IF';
my $panel = 'DD';

my $gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
  -genomic_feature_id => $genomic_feature->dbID,
  -disease_id => $disease->dbID,
  -DD_Category => $DDD_category,
  -is_visible => 1,
  -panel => $panel,
  -adaptor => $gfda,
);
throws_ok { $gfda->store($gfd, $user); } qr/DDD_category or DDD_category_attrib is required/, 'Die on missing DDD category';

$gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
  -genomic_feature_id => $genomic_feature->dbID,
  -disease_id => $disease->dbID,
  -DDD_Category => $DDD_category,
  -is_visible => 1,
  -panels => $panel,
  -adaptor => $gfda,
);
throws_ok { $gfda->store($gfd, $user); } qr/panel or panel_attrib is required/, 'Die on missing panel';

$gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
  -genomic_feature_id => $genomic_feature->dbID,
  -disease_id => $disease->dbID,
  -DDD_Category => 'both',
  -is_visible => 1,
  -panel => $panel,
  -adaptor => $gfda,
);
throws_ok { $gfda->store($gfd, $user); } qr/Could not get DDD category attrib id for value/, 'Die on wrong value for DDD_category_attrib';

$gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
  -genomic_feature_id => $genomic_feature->dbID,
  -disease_id => $disease->dbID,
  -DDD_Category => $DDD_category,
  -is_visible => 1,
  -panel => 'DDD',
  -adaptor => $gfda,
);
throws_ok { $gfda->store($gfd, $user); } qr/Could not get panel attrib id for value/, 'Die on wrong value for panel_attrib';

$gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
  -genomic_feature_id => $genomic_feature->dbID,
  -disease_id => $disease->dbID,
  -DDD_category => $DDD_category,
  -is_visible => 1,
  -panel => $panel,
  -adaptor => $gfda,
);

ok($gfda->store($gfd, $user), 'store');

my $GFD_id = $gfd->{genomic_feature_disease_id};

$gfd = $gfda->fetch_by_dbID($GFD_id);
$gfd->DDD_category('possible DD gene');
ok($gfda->update($gfd, $user), 'update');

$gfd = $gfda->fetch_by_dbID($GFD_id);
ok($gfd->DDD_category eq 'possible DD gene', 'test update');

my $dbh = $gfda->dbc->db_handle;
$dbh->do(qq{DELETE FROM genomic_feature_disease WHERE genomic_feature_disease_id=$GFD_id;}) or die $dbh->errstr;

#fetch_by_dbID
my $dbID = 1797; 
$gfd = $gfda->fetch_by_dbID($dbID);
ok($gfd->dbID == $dbID, 'fetch_by_dbID');

#fetch_by_GenomicFeature_Disease
$gene_symbol = 'PRMT9';
$genomic_feature = $gfa->fetch_by_gene_symbol($gene_symbol);
$disease_name = 'AUTOSOMAL RECESSIVE MENTAL RETARDATION';
$disease = $da->fetch_by_name($disease_name);

$gfd = $gfda->fetch_by_GenomicFeature_Disease($genomic_feature, $disease);
ok($gfd->dbID == $dbID, 'fetch_by_GenomicFeature_Disease');

#fetch_by_GenomicFeature_Disease_panel_id
$gfd = $gfda->fetch_by_GenomicFeature_Disease_panel_id($genomic_feature, $disease, 38);
ok($gfd->dbID == $dbID, 'fetch_by_GenomicFeature_Disease_panel_id');

#fetch_all_by_GenomicFeature
my $gfds = $gfda->fetch_all_by_GenomicFeature($genomic_feature); 
ok(scalar @$gfds == 1, 'fetch_all_by_GenomicFeature');

#fetch_all_by_GenomicFeature_panel
$gfds = $gfda->fetch_all_by_GenomicFeature_panel($genomic_feature, 'DD'); 
ok(scalar @$gfds == 1, 'fetch_all_by_GenomicFeature_panel');

#fetch_all_by_Disease
$gfds = $gfda->fetch_all_by_Disease($disease); 
ok(scalar @$gfds == 1, 'fetch_all_by_Disease');

#fetch_all_by_Disease_panel
$gfds = $gfda->fetch_all_by_Disease_panel($disease, 'DD'); 
ok(scalar @$gfds == 1, 'fetch_all_by_Disease_panel');

$gfd = $gfds->[0];
$gfda->delete($gfd, $user);

#fetch_all_by_disease_id

#fetch_all

done_testing();
1;

