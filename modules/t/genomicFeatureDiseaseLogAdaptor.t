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

my $gfd_adaptor = $g2pdb->get_GenomicFeatureDiseaseAdaptor;
my $gfd_log_adaptor = $g2pdb->get_GenomicFeatureDiseaseLogAdaptor;
my $ua = $g2pdb->get_UserAdaptor;

ok($gfd_adaptor && $gfd_adaptor->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseAdaptor'), 'isa GenomicFeatureDiseaseAdaptor');
ok($gfd_log_adaptor && $gfd_log_adaptor->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseLogAdaptor'), 'isa GenomicFeatureDiseaseLogAdaptor');

# store: is tested in genomicFeatureDiseaseAdaptor.t

#fetch_by_dbID
my $dbID = 22; 
my $gfd_log = $gfd_log_adaptor->fetch_by_dbID($dbID);
ok($gfd_log->dbID == $dbID, 'fetch_by_dbID');
ok($gfd_log->allelic_requirement eq 'monoallelic', 'fetch_by_dbID allelic_requirement');
ok($gfd_log->allelic_requirement_attrib eq '14', 'fetch_by_dbID allelic_requirement_attrib');
ok($gfd_log->mutation_consequence eq 'dominant negative', 'fetch_by_dbID mutation_consequence');
ok($gfd_log->mutation_consequence_attrib eq '24', 'fetch_by_dbID mutation_consequence_attrib');
ok($gfd_log->created eq '2015-07-22 16:14:09', 'fetch_by_dbID created');
ok($gfd_log->user_id == 4, 'fetch_by_dbID user_id');
ok($gfd_log->action eq 'create', 'fetch_by_dbID action');

# fetch_all_by_GenomicFeatureDisease
my $gfd = $gfd_adaptor->fetch_by_dbID(2181);
my $gfd_logs = $gfd_log_adaptor->fetch_all_by_GenomicFeatureDisease($gfd);
ok(scalar @$gfd_logs == 2, 'fetch_all_by_GenomicFeatureDisease');

# fetch_all_most_recent
$gfd_logs = $gfd_log_adaptor->fetch_all_by_most_recent;
ok(scalar @$gfd_logs == 10, 'fetch_all_by_most_recent');
my $limit = undef;
my $action = 'update';
$gfd_logs = $gfd_log_adaptor->fetch_all_by_most_recent($limit, $action);
my $count = grep {$_->action eq $action} @$gfd_logs;
ok($count == 10, 'fetch_all_by_most_recent action=update');
$limit = 20;
$action = undef;
$gfd_logs = $gfd_log_adaptor->fetch_all_by_most_recent($limit, $action);
$count = grep {$_->action eq 'create'} @$gfd_logs;
ok($count == 20, 'fetch_all_by_most_recent limit=20');


done_testing();
1;

