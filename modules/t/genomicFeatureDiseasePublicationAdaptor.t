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

my $gfdpa = $g2pdb->get_GenomicFeatureDiseasePublicationAdaptor;
my $gfda = $g2pdb->get_GenomicFeatureDiseaseAdaptor;
my $pa = $g2pdb->get_PublicationAdaptor;

ok($gfdpa && $gfdpa->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseasePublicationAdaptor'), 'isa GenomicFeatureDiseasePublicationAdaptor');

my $GFDP_id = 291;

my $GFDP = $gfdpa->fetch_by_dbID($GFDP_id);
ok($GFDP->dbID == $GFDP_id, 'fetch_by_dbID');

my $GFD_id = 133;
my $publication_id = 16168;
$GFDP = $gfdpa->fetch_by_GFD_id_publication_id($GFD_id, $publication_id);
ok($GFDP->dbID == $GFDP_id, 'fetch_by_GFD_id_publication_id');

my $GFD = $gfda->fetch_by_dbID($GFD_id);
my $GFDPs = $gfdpa->fetch_all_by_GenomicFeatureDisease($GFD);
ok(scalar @$GFDPs == 1, 'fetch_all_by_GenomicFeatureDisease');

my $publication = Bio::EnsEMBL::G2P::Publication->new(
  -pmid => 12345,
  -title => 'test_title',
  -source => 'test_source',
  -adaptor => $pa,
);

$pa->store($publication);

$publication_id = $publication->{publication_id};
$GFDP = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication->new(
  -genomic_feature_disease_id => 235,
  -publication_id => $publication_id,
  -adaptor => $gfdpa
);

ok($gfdpa->store($GFDP), 'store');
$GFDP_id = $GFDP->{genomic_feature_disease_publication_id};

my $dbh = $gfda->dbc->db_handle;
$dbh->do(qq{DELETE FROM publication WHERE publication_id=$publication_id;}) or die $dbh->errstr;
$dbh->do(qq{DELETE FROM genomic_feature_disease_publication WHERE genomic_feature_disease_publication_id=$GFDP_id;}) or die $dbh->errstr;

done_testing();
1;
