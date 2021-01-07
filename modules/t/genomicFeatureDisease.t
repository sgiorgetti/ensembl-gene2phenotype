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

my $dbID = 133;
my $genomic_feature_id = 59384;
my $disease_id = 326;
my $confidence_category_attrib = 32;
my $is_visible = 1;
my $panel = '38';

my $gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
  -genomic_feature_id => $genomic_feature_id,
  -disease_id => $disease_id,
  -confidence_category_attrib => $confidence_category_attrib,
  -is_visible => $is_visible,
  -panel => $panel,
  -adaptor => $gfda,
);

ok($gfd->genomic_feature_id == $genomic_feature_id, 'genomic_feature_id');
ok($gfd->disease_id == $disease_id, 'disease_id');
ok($gfd->confidence_category_attrib == $confidence_category_attrib, 'confidence_category_attrib');
ok($gfd->confidence_category eq 'confirmed DD gene', 'confidence_category');
ok($gfd->is_visible == 1, 'is_visible');
ok($gfd->panel eq $panel, 'panel');


$gfd = $gfda->fetch_by_dbID($dbID);
my $GFDAs = $gfd->get_all_GenomicFeatureDiseaseActions();
ok(scalar @$GFDAs == 1, 'count genomic_feature_disease_actions');

my $gf = $gfd->get_GenomicFeature();
ok($gf->gene_symbol eq 'KIF1BP', 'get_GenomicFeature');

my $disease = $gfd->get_Disease();
ok($disease->name eq 'GOLDBERG-SHPRINTZEN MEGACOLON SYNDROME (GOSHS)', 'get_Disease');

my $GFDPs = $gfd->get_all_GFDPublications();
ok(scalar @$GFDPs == 1, 'get_all_GFDPublications');

$GFDPs = $gfd->get_all_GFDPhenotypes();
ok(scalar @$GFDPs == 20, 'get_all_GFDPhenotypes');

my $GFDOs = $gfd->get_all_GFDOrgans();
ok(@$GFDOs == 2, 'get_all_GFDOrgans');

done_testing();

1;
