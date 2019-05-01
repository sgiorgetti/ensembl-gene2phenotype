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

use Data::Dumper;
use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $pa = $g2pdb->get_PhenotypeAdaptor;

ok($pa && $pa->isa('Bio::EnsEMBL::G2P::DBSQL::PhenotypeAdaptor'), 'isa phenotype_adaptor');

my $dbID = 5;
my $stable_id = 'HP:0000006'; 
my $name = 'Autosomal dominant inheritance'; 
my $description = undef;

my $phenotype = $pa->fetch_by_phenotype_id($dbID);
ok($phenotype->dbID == $dbID, 'fetch_by_phenotype_id');

$phenotype = $pa->fetch_by_dbID($dbID);
ok($phenotype->dbID == $dbID, 'fetch_by_dbID');

$phenotype = $pa->fetch_by_stable_id($stable_id);
ok($phenotype->stable_id eq $stable_id, 'fetch_by_stable_Id');

$phenotype = $pa->fetch_by_name($name);
ok($phenotype->name eq $name, 'fetch_by_name');

my $phenotypes = $pa->fetch_all();
ok(scalar @$phenotypes == 173, 'fetch_all');

$phenotype = Bio::EnsEMBL::G2P::Phenotype->new(
  -name => 'test_phenotype',
  -adaptor => $pa,
);

ok($pa->store($phenotype), 'store');

my $phenotype_id = $phenotype->{phenotype_id};

my $dbh = $pa->dbc->db_handle;
$dbh->do(qq{DELETE FROM phenotype WHERE phenotype_id=$phenotype_id;}) or die $dbh->errstr;

my $mappings = $pa->_get_mesh2hp_mappings('MESH:D012174');
ok(scalar keys %{$mappings->{'MESH:D012174'}} == 3, 'fetch_mesh_ids');

$phenotypes = $pa->fetch_all_by_name_list_source(['Osteochondrodysplasias', 'Osteogenesis Imperfecta'], 'MESH');
ok (scalar @$phenotypes == 2, 'fetch_all_by_name_list_source');

$phenotype = $pa->fetch_by_stable_id_source('MESH:D009886', 'MESH');
$phenotype_id = $phenotype->phenotype_id;

my $add_mesh2hp_mappings = 1;
$pa->store_all_by_stable_ids_source(['MESH:D009886'], 'MESH', $add_mesh2hp_mappings);
my $mesh2hp_mappings = $pa->_get_mesh2hp_mappings_from_db([$phenotype]);
ok(scalar keys %{$mesh2hp_mappings->{$phenotype_id}} == 4, 'count HP mappings for given mesh phenotype');

done_testing();
1;
