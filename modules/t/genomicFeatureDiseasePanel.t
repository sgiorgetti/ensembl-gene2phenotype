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
use Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');
my $gfdpa = $g2pdb->get_GenomicFeatureDiseasePanelAdaptor;

my $genomic_feature_disease_id = 3857;
my $confidence_category = 'confirmed';
my $is_visible = 1;
my $panel = 'Skin';

my $gfd_panel = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel->new(
  -genomic_feature_disease_id => $genomic_feature_disease_id,
  -confidence_category => $confidence_category,
  -is_visible => $is_visible,
  -panel => $panel,
  -adaptor => $gfdpa,
);
ok($gfd_panel->genomic_feature_disease_id == $genomic_feature_disease_id, 'genomic_feature_disease_id');
ok($gfd_panel->confidence_category eq $confidence_category, 'confidence_category');
ok($gfd_panel->is_visible == $is_visible, 'is_visible');
ok($gfd_panel->panel eq $panel, 'panel');
ok($gfd_panel->panel_attrib == 41, 'panel_attrib');
ok($gfd_panel->confidence_category_attrib == 32, 'confidence_category_attrib');

my $dbID = 1928;
$gfd_panel = $gfdpa->fetch_by_dbID($dbID);

ok($gfd_panel->dbID == $dbID, 'dbID');
ok($gfd_panel->genomic_feature_disease_id == 2412, 'genomic_feature_disease_id');

ok($gfd_panel->confidence_category eq 'probable', 'confidence_category');
ok($gfd_panel->confidence_category_attrib == 34, 'confidence_category_attrib');
ok($gfd_panel->is_visible == 1, 'is_visible');
ok($gfd_panel->panel eq 'Eye', 'panel');
ok($gfd_panel->panel_attrib == 40, 'panel_attrib');

done_testing();

1;
