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

use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfdoa = $g2pdb->get_GenomicFeatureDiseaseOrganAdaptor;
my $gfda = $g2pdb->get_GenomicFeatureDiseaseAdaptor;

ok($gfdoa && $gfdoa->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseOrganAdaptor'), 'isa GenomicFeatureDiseaseOrganAdaptor');

my $dbID = 261;
my $GFD_id = 133;
my $organ_id = 15;

my $GFDO = $gfdoa->fetch_by_dbID($dbID);
ok($GFDO->dbID == $dbID, 'fetch_by_dbID');

$GFDO = $gfdoa->fetch_by_GFD_id_organ_id($GFD_id, $organ_id);
ok($GFDO->dbID == $dbID, 'fetch_by_GFD_id_organ_id');

my $GFD = $gfda->fetch_by_dbID($GFD_id);
my $GFDOs = $gfdoa->fetch_all_by_GenomicFeatureDisease($GFD);
ok(scalar @$GFDOs == 2, 'fetch_all_by_GenomicFeatureDisease');

$GFDO = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseOrgan->new(
  -genomic_feature_disease_id => 133,
  -organ_id => 1,
  -adaptor => $gfdoa
);

ok($gfdoa->store($GFDO), 'store');

my $GFDO_id = $GFDO->{genomic_feature_disease_organ_id};

my $dbh = $gfda->dbc->db_handle;
$dbh->do(qq{DELETE FROM genomic_feature_disease_organ WHERE genomic_feature_disease_organ_id=$GFDO_id;}) or die $dbh->errstr;

done_testing();
1;
