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
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $oa = $g2pdb->get_OrganAdaptor;

ok($oa && $oa->isa('Bio::EnsEMBL::G2P::DBSQL::OrganAdaptor'), 'isa organ_adaptor');

my $organ_id = 1;
my $name = 'Teeth & Dentitian'; 

my $organ = $oa->fetch_by_organ_id($organ_id);
ok($organ->dbID == $organ_id, 'fetch_by_organ_id');

$organ = $oa->fetch_by_dbID($organ_id);
ok($organ->dbID == $organ_id, 'fetch_by_dbID');

$organ = $oa->fetch_by_name($name);
ok($organ->name eq $name, 'fetch_by_name');

my $organs = $oa->fetch_all();
ok(scalar @$organs == 23, 'fetch_all');

$organs = $oa->fetch_all_by_panel_id(1);
ok(scalar @$organs == 4, 'fetch_all_by_panel_id');

$organ = Bio::EnsEMBL::G2P::Organ->new(
  -name => 'test_organ',
  -adaptor => $oa,
);
  
ok($oa->store($organ), 'store');

$organ_id = $organ->{organ_id};

my $dbh = $oa->dbc->db_handle;
$dbh->do(qq{DELETE FROM organ WHERE organ_id=$organ_id;}) or die $dbh->errstr;

done_testing();
1;
