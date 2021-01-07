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
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfdoa = $g2pdb->get_GenomicFeatureDiseaseOrganAdaptor;

ok($gfdoa && $gfdoa->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseOrganAdaptor'), 'isa GenomicFeatureDiseaseOrganAdaptor');

my $GFD_organ_id = 261;
my $genomic_feature_disease_id = 133;
my $organ_id = 15;

my $GFDO = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseOrgan->new(
  -genomic_feature_disease_organ_id => $GFD_organ_id,
  -genomic_feature_disease_id => $genomic_feature_disease_id,
  -organ_id => $organ_id,
  -adaptor => $gfdoa,
);

ok($GFDO->dbID == $GFD_organ_id, 'dbID');

my $GFD = $GFDO->get_GenomicFeatureDisease();
ok($GFD->dbID == $genomic_feature_disease_id, 'get_GenomicFeatureDisease');

my $organ = $GFDO->get_Organ();
ok($organ->dbID == $organ_id, 'get_Organ');

done_testing();
1;
