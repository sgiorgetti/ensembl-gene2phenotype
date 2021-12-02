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
use Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanelLog;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfd_panel_log_adaptor = $g2pdb->get_GenomicFeatureDiseasePanelLogAdaptor;

my $dbID = 1111;
my $genomic_feature_disease_panel_id = 1035; 
my $genomic_feature_disease_id = 1235;
my $confidence_category_attrib = '50';
my $confidence_category = 'definitive';
my $is_visible = 1;
my $panel_attrib = '38';
my $panel = 'DD';
my $user_id = 10;
my $action = 'create';

my $gfdpl = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanelLog->new(
  -genomic_feature_disease_panel_id => $genomic_feature_disease_panel_id,
  -genomic_feature_disease_id => $genomic_feature_disease_id,
  -confidence_category_attrib => $confidence_category_attrib,
  -is_visible => $is_visible,
  -panel_attrib => $panel_attrib,
  -user_id => $user_id,
  -action => $action,
  -adaptor => $gfd_panel_log_adaptor,
);

ok($gfdpl->genomic_feature_disease_panel_id == $genomic_feature_disease_panel_id, 'genomic_feature_disease_panel_id');
ok($gfdpl->genomic_feature_disease_id == $genomic_feature_disease_id, 'genomic_feature_disease_id');
ok($gfdpl->confidence_category_attrib eq $confidence_category_attrib, 'confidence_category_attrib');
ok($gfdpl->confidence_category eq $confidence_category, 'confidence_category');
ok($gfdpl->panel_attrib eq $panel_attrib, 'panel_attrib');
ok($gfdpl->panel eq $panel, 'panel');
ok($gfdpl->action eq $action, 'action');
ok($gfdpl->user_id == $user_id, 'user_id');
ok($gfdpl->{adaptor} && $gfdpl->{adaptor}->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseasePanelLogAdaptor'), 'isa GenomicFeatureDiseasePanelLogAdaptor');

done_testing();

1;
