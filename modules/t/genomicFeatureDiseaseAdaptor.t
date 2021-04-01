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
use Test::Exception;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfda = $g2pdb->get_GenomicFeatureDiseaseAdaptor;
my $da = $g2pdb->get_DiseaseAdaptor;
my $gfa = $g2pdb->get_GenomicFeatureAdaptor;
my $ua = $g2pdb->get_UserAdaptor;

ok($gfda && $gfda->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseAdaptor'), 'isa GenomicFeatureDiseaseAdaptor');


# fetch_all
# fetch_all_by_GenomicFeature_Disease
# fetch_all_by_GenomicFeatureDisease --> backwards compatible
# fetch_by_GenomicFeatureDisease
# fetch_all_by_GenomicFeature
# fetch_all_by_constraints(hash)
# fetch_all_by_GenomicFeature_constraints
# add, store
# update

# store
my $disease_name = 'KABUKI SYNDROME';
my $disease = $da->fetch_by_name($disease_name);
ok($disease->name eq $disease_name, 'disease object');
my $gene_symbol = 'P3H1';
my $genomic_feature = $gfa->fetch_by_gene_symbol($gene_symbol); 
ok($genomic_feature->gene_symbol eq $gene_symbol, 'genomic_feature object');

my $username = 'user1';
my $user = $ua->fetch_by_username($username);
ok($user->username eq $username, 'user object');

my $allelic_requirement = 'monoallelic';
my $mutation_consequence = 'all missense/in frame';

my $gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
  -genomic_feature_id => $genomic_feature->dbID,
  -disease_id => $disease->dbID,
  -allelic_requirement => $allelic_requirement,
  -adaptor => $gfda,
);
throws_ok { $gfda->store($gfd, $user); } qr/mutation_consequence or mutation_consequence_attrib is required/, 'Die on missing mutation consequence';

$gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
  -genomic_feature_id => $genomic_feature->dbID,
  -disease_id => $disease->dbID,
  -mutation_consequence => $mutation_consequence,
  -adaptor => $gfda,
);
throws_ok { $gfda->store($gfd, $user); } qr/allelic_requirement or allelic_requirement_attrib is required/, 'Die on missing allelic requirement';

$gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
  -genomic_feature_id => $genomic_feature->dbID,
  -disease_id => $disease->dbID,
  -allelic_requirement => $allelic_requirement,
  -mutation_consequence => 'cis-regulatory or promotor',
  -adaptor => $gfda,
);
throws_ok { $gfda->store($gfd, $user); } qr/Could not get mutation_consequence attrib id for value cis-regulatory or promotor/, 'Die on wrong mutation consequence value';

$gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
  -genomic_feature_id => $genomic_feature->dbID,
  -disease_id => $disease->dbID,
  -allelic_requirement => 'monoallelic,x-linked',
  -mutation_consequence => 'cis-regulatory or promotor mutation',
  -adaptor => $gfda,
);
throws_ok { $gfda->store($gfd, $user); } qr/Could not get attrib for value: x-linked/, 'Die on wrong allelic requirement value';

# store and delete 
#ok($gfda->store($gfd, $user), 'store');
#my $GFD_id = $gfd->{genomic_feature_disease_id};
#$gfd = $gfda->fetch_by_dbID($GFD_id);
#$gfd->confidence_category('possible DD gene');
#ok($gfda->update($gfd, $user), 'update');
#$gfd = $gfda->fetch_by_dbID($GFD_id);
#ok($gfd->confidence_category eq 'possible DD gene', 'test update');
#my $dbh = $gfda->dbc->db_handle;
#$dbh->do(qq{DELETE FROM genomic_feature_disease WHERE genomic_feature_disease_id=$GFD_id;}) or die $dbh->errstr;

#fetch_by_dbID
my $dbID = 1797; 
$gfd = $gfda->fetch_by_dbID($dbID);
ok($gfd->dbID == $dbID, 'fetch_by_dbID');
ok($gfd->allelic_requirement eq 'biallelic', 'fetch_by_dbID allelic_requirement');
ok($gfd->mutation_consequence eq 'all missense/in frame', 'fetch_by_dbID mutation_consequence');
ok($gfd->get_Disease->name eq 'AUTOSOMAL RECESSIVE MENTAL RETARDATION', 'fetch_by_dbID disease name');
ok($gfd->get_GenomicFeature->gene_symbol eq 'PRMT9', 'fetch_by_dbID gene symbol');

#fetch_all_by_GenomicFeature_Disease
$gene_symbol = 'PRMT9';
$genomic_feature = $gfa->fetch_by_gene_symbol($gene_symbol);
$disease_name = 'AUTOSOMAL RECESSIVE MENTAL RETARDATION';
$disease = $da->fetch_by_name($disease_name);
my $gfds = $gfda->fetch_all_by_GenomicFeature_Disease($genomic_feature, $disease);
ok($gfd->dbID == $gfds->[0]->dbID, 'fetch_all_by_GenomicFeature_Disease');

#fetch_all_by_GenomicFeature
$gfds = $gfda->fetch_all_by_GenomicFeature($genomic_feature); 
ok(scalar @$gfds == 1, 'fetch_all_by_GenomicFeature');

#fetch_all_by_Disease
$gfds = $gfda->fetch_all_by_Disease($disease); 
ok(scalar @$gfds == 48, 'fetch_all_by_Disease');

#fetch_all_by_Disease_panels
$gfds = $gfda->fetch_all_by_Disease_panels($disease, ['DD']);
ok(scalar @$gfds == 48, 'fetch_all_by_Disease_panels');

#fetch_all_by_GenomicFeature_constraints
$gene_symbol = 'CACNA1G';
$genomic_feature = $gfa->fetch_by_gene_symbol($gene_symbol);
$gfds = $gfda->fetch_all_by_GenomicFeature_constraints($genomic_feature, {'allelic_requirement' => 'biallelic', 'mutation_consequence' => 'loss of function'});
ok(scalar @$gfds == 1, 'fetch_all_by_GenomicFeature_constraints');

done_testing();
1;

