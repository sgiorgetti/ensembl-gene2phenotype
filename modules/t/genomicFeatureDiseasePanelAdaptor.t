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
use Test::Exception;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfdpa = $g2pdb->get_GenomicFeatureDiseasePanelAdaptor;
my $gfd_panel_log_adaptor = $g2pdb->get_GenomicFeatureDiseasePanelLogAdaptor;
my $gfda = $g2pdb->get_GenomicFeatureDiseaseAdaptor;

ok($gfdpa && $gfdpa->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseasePanelAdaptor'), 'isa GenomicFeatureDiseasePanelAdaptor');

my $ua = $g2pdb->get_UserAdaptor;
my $username = 'user1';
my $user = $ua->fetch_by_username($username);
ok($user->username eq $username, 'user object');

#store, delete, update, update_log
#fetch_all
#fetch_all_by_GenomicFeatureDisease_panel
#fetch_all_by_GenomicFeatureDisease
#fetch_by_GenomicFeatureDisease_panel
#fetch_all_by_GenomicFeature_panel
#fetch_all_by_GenomicFeature_panels
#fetch_all_by_Disease
#fetch_all_by_Disease_panel
#fetch_all_by_Disease_panels
#fetch_all_by_disease_id
#fetch_all_by_panel
#fetch_all_by_panel_restricted
#get_statistics
#fetch_all_by_panel_without_publications
#fetch_all

my $genomic_feature_disease_id = 2409;

my $gfd_panel = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel->new(
  -genomic_feature_disease_id => $genomic_feature_disease_id,
  -confidence_category => 'confirmed',
  -is_visible => 1,
  -adaptor => $gfdpa,
);
throws_ok { $gfdpa->store($gfd_panel, $user); } qr/panel or panel_attrib is required/, 'Die on missing panel';

$gfd_panel = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel->new(
  -genomic_feature_disease_id => $genomic_feature_disease_id,
  -panel => 'DD',
  -is_visible => 1,
  -adaptor => $gfdpa,
);
throws_ok { $gfdpa->store($gfd_panel, $user); } qr/confidence_category or confidence_category_attrib is required/, 'Die on missing confidence category';

$gfd_panel = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel->new(
  -genomic_feature_disease_id => $genomic_feature_disease_id,
  -confidence_category => 'maybe',
  -panel => 'DD',
  -is_visible => 1,
  -adaptor => $gfdpa,
);
throws_ok { $gfdpa->store($gfd_panel, $user); } qr/Could not get attrib for value: maybe/, 'Die on wrong confidence category';

$gfd_panel = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel->new(
  -genomic_feature_disease_id => $genomic_feature_disease_id,
  -confidence_category => 'confirmed',
  -panel => 'Brain',
  -is_visible => 1,
  -adaptor => $gfdpa,
);
throws_ok { $gfdpa->store($gfd_panel, $user); } qr/Could not get attrib for value: Brain/, 'Die on wrong panel';

# store, update, delete
$multi->hide('gene2phenotype', 'genomic_feature_disease_panel', 'genomic_feature_disease_panel_log', 'genomic_feature_disease_panel_deleted');

$gfd_panel = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel->new(
  -genomic_feature_disease_id => $genomic_feature_disease_id,
  -confidence_category => 'confirmed',
  -panel => 'DD',
  -is_visible => 1,
  -adaptor => $gfdpa,
);
$gfd_panel = $gfdpa->store($gfd_panel, $user);
ok($gfd_panel->genomic_feature_disease_id == $genomic_feature_disease_id, 'store genomic_feature_disease_id');
ok($gfd_panel->confidence_category eq 'confirmed', 'store confidence_category');
ok($gfd_panel->panel eq 'DD', 'store panel');
ok($gfd_panel->is_visible == 1, 'store is_visible');
my $gfd_panel_logs = $gfd_panel_log_adaptor->fetch_all_by_GenomicFeatureDiseasePanel($gfd_panel);
my ($gfd_panel_log) = grep {$_->action eq 'create'} @$gfd_panel_logs;
ok($gfd_panel_log->genomic_feature_disease_id == $genomic_feature_disease_id, 'from log table: genomic_feature_disease_id');
ok($gfd_panel_log->confidence_category eq 'confirmed', 'from log table: confidence_category');
ok($gfd_panel_log->panel eq 'DD', 'from log table: panel');
ok($gfd_panel_log->is_visible == 1, 'from log table: is_visible');

$gfd_panel->confidence_category('possible');
$gfd_panel = $gfdpa->update($gfd_panel, $user);
$gfd_panel = $gfdpa->fetch_by_dbID($gfd_panel->dbID);
ok($gfd_panel->confidence_category eq 'possible', 'update confidence_category');
$gfd_panel_logs = $gfd_panel_log_adaptor->fetch_all_by_GenomicFeatureDiseasePanel($gfd_panel);
($gfd_panel_log) = grep {$_->action eq 'update'} @$gfd_panel_logs;
ok($gfd_panel_log->confidence_category eq 'possible', 'from log table, after update: confidence_category');

$gfdpa->delete($gfd_panel, $user);
my $gfd_panel_deleted = $gfdpa->fetch_by_dbID($gfd_panel->dbID);
ok(!defined $gfd_panel_deleted, 'delete');

$gfd_panel_logs = $gfd_panel_log_adaptor->fetch_all_by_GenomicFeatureDiseasePanel($gfd_panel);
ok(scalar @$gfd_panel_logs == 0, 'No entries in log table after GenomicFeatureDiseasePanel has been deleted');

$multi->restore('gene2phenotype', 'genomic_feature_disease_panel', 'genomic_feature_disease_panel_log', 'genomic_feature_disease_panel_deleted');

#fetch_by_dbID
my $dbID = 33; 
$gfd_panel = $gfdpa->fetch_by_dbID($dbID);
ok($gfd_panel->dbID == $dbID, 'fetch_by_dbID');

ok($gfd_panel->panel eq 'DD', 'fetch_by_dbID panel');
ok($gfd_panel->confidence_category eq 'confirmed', 'fetch_by_dbID confidence category');
ok($gfd_panel->is_visible == 1, 'fetch_by_dbID is visible');

#fetch_all_by_panel
my $gfd_panels = $gfdpa->fetch_all_by_panel('DD');
ok(scalar @$gfd_panels == 2409, 'fetch_all_by_panel');
#fetch_all_by_panel_restricted
$gfd_panels = $gfdpa->fetch_all_by_panel_restricted('DD');
ok(scalar @$gfd_panels == 0, 'fetch_all_by_panel_restricted');

#fetch_all_by_GenomicFeatureDisease
my $gfd = $gfda->fetch_by_dbID(2389);
$gfd_panels = $gfdpa->fetch_all_by_GenomicFeatureDisease($gfd);
ok(scalar @$gfd_panels == 1, 'fetch_all_by_GenomicFeatureDisease');

#fetch_by_GenomicFeatureDisease_panel
$gfd_panel = $gfdpa->fetch_by_GenomicFeatureDisease_panel($gfd, 'DD');
ok($gfd_panel->dbID == 1907, 'fetch_by_GenomicFeatureDisease_panel');

done_testing();
1;

