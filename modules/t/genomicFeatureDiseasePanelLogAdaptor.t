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

my $gfd_panel_adaptor = $g2pdb->get_GenomicFeatureDiseasePanelAdaptor;
my $gfd_panel_log_adaptor = $g2pdb->get_GenomicFeatureDiseasePanelLogAdaptor;

ok($gfd_panel_adaptor && $gfd_panel_adaptor->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseasePanelAdaptor'), 'isa GenomicFeatureDiseasePanelAdaptor');
ok($gfd_panel_log_adaptor && $gfd_panel_log_adaptor->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseasePanelLogAdaptor'), 'isa GenomicFeatureDiseasePanelLogAdaptor');

# store: is tested in genomicFeatureDiseasePanelAdaptor.t

#fetch_by_dbID
my $dbID = 55; 
my $gfd_panel_log = $gfd_panel_log_adaptor->fetch_by_dbID($dbID);
ok($gfd_panel_log->dbID == $dbID, 'fetch_by_dbID');
ok($gfd_panel_log->created eq '2015-07-22 16:14:13', 'fetch_by_dbID created');
ok($gfd_panel_log->user_id == 4, 'fetch_by_dbID user_id');
ok($gfd_panel_log->action eq 'create', 'fetch_by_dbID action');

# fetch_all_by_GenomicFeatureDiseasePanel
my $gfd_panel = $gfd_panel_adaptor->fetch_by_dbID(836);
my $gfd_panel_logs = $gfd_panel_log_adaptor->fetch_all_by_GenomicFeatureDiseasePanel($gfd_panel);
ok(scalar @$gfd_panel_logs == 1, 'fetch_all_by_GenomicFeatureDiseasePanel');

# fetch_all_most_recent
my $panel = 'DD';
$gfd_panel_logs = $gfd_panel_log_adaptor->fetch_all_by_most_recent($panel);
ok(scalar @$gfd_panel_logs == 10, 'fetch_all_by_most_recent');

done_testing();
1;

