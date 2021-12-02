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
use Bio::EnsEMBL::G2P::GenomicFeatureDisease;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');
my $gfda = $g2pdb->get_GenomicFeatureDiseaseAdaptor;

my $genomic_feature_id = 59384;
my $disease_id = 326;
my $allelic_requirement_attrib = 59;
my $mutation_consequence_attrib = 76;
my $mutation_consequence_flag_attrib = 71;
my $restricted_mutation_set = 0;

my $gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
  -genomic_feature_id => $genomic_feature_id,
  -disease_id => $disease_id,
  -allelic_requirement_attrib => $allelic_requirement_attrib,
  -mutation_consequence_attrib => $mutation_consequence_attrib,
  -mutation_consequence_flag_attrib => $mutation_consequence_flag_attrib,
  -restricted_mutation_set => $restricted_mutation_set,
  -adaptor => $gfda,
);
ok($gfd->genomic_feature_id == $genomic_feature_id, 'genomic_feature_id');
ok($gfd->disease_id == $disease_id, 'disease_id');
ok($gfd->allelic_requirement eq 'biallelic_autosomal', 'allelic_requirement');
ok($gfd->mutation_consequence eq 'absent gene product', 'mutation_consequence');
ok($gfd->mutation_consequence_flag eq 'likely to escape nonsense mediated decay', 'mutation_consequence_flag');
ok($gfd->restricted_mutation_set == 0, 'restricted_mutation_set');

my $dbID = 133;
$gfd = $gfda->fetch_by_dbID($dbID);

my $gf = $gfd->get_GenomicFeature();
ok($gf->gene_symbol eq 'KIFBP', 'get_GenomicFeature');

my $disease = $gfd->get_Disease();
ok($disease->name eq 'GOLDBERG-SHPRINTZEN MEGACOLON SYNDROME', 'get_Disease');

ok($gfd->allelic_requirement eq 'biallelic_autosomal', 'allelic_requirement');

ok($gfd->mutation_consequence eq 'absent gene product', 'mutation_consequence');

ok($gfd->restricted_mutation_set == 0, 'restricted_mutation_set');

my $GFDPs = $gfd->get_all_GFDPublications();
ok(scalar @$GFDPs == 1, 'get_all_GFDPublications');

$GFDPs = $gfd->get_all_GFDPhenotypes();
ok(scalar @$GFDPs == 20, 'get_all_GFDPhenotypes');

my $GFDOs = $gfd->get_all_GFDOrgans();
ok(@$GFDOs == 2, 'get_all_GFDOrgans');

done_testing();

1;
