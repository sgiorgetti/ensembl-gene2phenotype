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

my $dbID = 85;
my $name = 'SPONDYLOEPIPHYSEAL DYSPLASIA CONGENITA; SEDC'; 
my $mim = 183900;

my $disease = $da->fetch_by_dbID($dbID);
ok($disease->name eq $name, 'fetch_by_dbID');

$disease = $da->fetch_by_name($name);
ok($disease->dbID == $dbID, 'fetch_by_name');

$disease = $da->fetch_by_mim($mim); 
ok($disease->name eq $name, 'fetch_by_mim');

done_testing();
1;
