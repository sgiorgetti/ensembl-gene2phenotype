=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2020] EMBL-European Bioinformatics Institute
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

my $aa = $g2pdb->get_AttributeAdaptor;

ok($aa && $aa->isa('Bio::EnsEMBL::G2P::DBSQL::AttributeAdaptor'), 'isa AttributeAdaptor');

my $attrib_id = 1;
my $attrib_type_id = 1;
my $code = 'allelic_requirement';
my $name = 'Allelic requirement'; 
my $value = 'monoallelic (autosome)';

ok($aa->attrib_id_for_value($value) == $attrib_id, 'attrib_id_for_value');
ok($aa->attrib_value_for_id($attrib_id) eq $value, 'attrib_value_for_id');
ok($aa->attrib_id_for_type_value($code, $value) == $attrib_id, 'attrib_id_for_type_value');
my $attribs = $aa->get_attribs_by_type_value($code);
ok(scalar keys %$attribs == 20, 'get_attribs_by_type_value');

done_testing();
1;
