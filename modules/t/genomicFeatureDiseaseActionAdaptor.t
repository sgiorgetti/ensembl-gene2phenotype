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

my $gfdaa = $g2pdb->get_GenomicFeatureDiseaseActionAdaptor;
my $gfda = $g2pdb->get_GenomicFeatureDiseaseAdaptor;
my $ua = $g2pdb->get_UserAdaptor;

ok($gfdaa && $gfdaa->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseActionAdaptor'), 'isa GenomicFeatureDiseaseActionAdaptor');

my $GFD_id = 49;
my $GFD = $gfda->fetch_by_dbID($GFD_id);

my $GFDAs = $gfdaa->fetch_all_by_GenomicFeatureDisease($GFD);
ok(scalar @$GFDAs == 1, 'fetch_all_by_GenomicFeatureDisease');

my $GFDA_id = 50;
my $GFDA = $gfdaa->fetch_by_dbID($GFDA_id);
ok($GFDA->dbID == $GFDA_id, 'fetch_by_dbID');

my $user = $ua->fetch_by_dbID(1);

my $genomic_feature_disease_id = 49;
my $allelic_requirement_attrib = '15';
my $mutation_consequence_attrib = '25';

my $gfda = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseAction->new(
  -genomic_feature_disease_id => $genomic_feature_disease_id,
  -allelic_requirement_attrib => $allelic_requirement_attrib,
  -mutation_consequence_attrib => $mutation_consequence_attrib,
  -adaptor => $gfdaa,
);

ok($gfdaa->store($gfda, $user), 'store');
$GFDA_id = $gfda->{genomic_feature_disease_action_id};
$gfda = $gfdaa->fetch_by_dbID($GFDA_id);
$gfda->allelic_requirement('monoallelic (autosome)');
$gfda->mutation_consequence('increased gene dosage');
ok($gfdaa->update($gfda, $user), 'update');
$gfda = $gfdaa->fetch_by_dbID($GFDA_id);
ok($gfda->allelic_requirement eq 'monoallelic (autosome)', 'test update allelic requirement');
ok($gfda->mutation_consequence eq 'increased gene dosage', 'test update mutation consequence');
ok($gfdaa->delete($gfda, $user), 'delete');

done_testing();
1;
