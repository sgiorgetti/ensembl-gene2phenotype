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

my $da = $g2pdb->get_DiseaseAdaptor;

ok($da && $da->isa('Bio::EnsEMBL::G2P::DBSQL::DiseaseAdaptor'), 'isa disease_adaptor');

my $dbID = 35;
my $name = 'KABUKI SYNDROME (KABS)'; 
my $mim = 147920;

my $disease = $da->fetch_by_dbID($dbID);
ok($disease->name eq $name, 'fetch_by_dbID');

$disease = $da->fetch_by_name($name);
ok($disease->dbID == $dbID, 'fetch_by_name');

$disease = $da->fetch_by_mim($mim); 
ok($disease->name eq $name, 'fetch_by_mim');

$disease = Bio::EnsEMBL::G2P::Disease->new(
  -name => 'disease_name',
  -mim => 12345,
);

ok($da->store($disease), 'store');

$disease = $da->fetch_by_name('disease_name');
ok($disease && $disease->name eq 'disease_name', 'fetch stored');

$disease->name('update_name');
ok($da->update($disease), 'update');
$disease = $da->fetch_by_name('update_name');
ok($disease && $disease->name eq 'update_name', 'fetch updated');

done_testing();
1;
