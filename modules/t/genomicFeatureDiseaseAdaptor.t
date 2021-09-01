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
my $gfd_log_adaptor = $g2pdb->get_GenomicFeatureDiseaseLogAdaptor;

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

my $allelic_requirement = 'monoallelic_autosomal';
my $mutation_consequence = 'altered gene product structure';

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
throws_ok { $gfda->store($gfd, $user); } qr/Could not get attrib for value: cis-regulatory or promotor/, 'Die on wrong mutation consequence value';

$gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
  -genomic_feature_id => $genomic_feature->dbID,
  -disease_id => $disease->dbID,
  -allelic_requirement => 'monoallelic_autosomal,x-linked',
  -mutation_consequence => 'cis-regulatory or promotor mutation',
  -adaptor => $gfda,
);
throws_ok { $gfda->store($gfd, $user); } qr/Could not get attrib for value: x-linked/, 'Die on wrong allelic requirement value';

# store, update
$multi->hide('gene2phenotype', 'genomic_feature_disease', 'genomic_feature_disease_log');

$gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
  -genomic_feature_id => $genomic_feature->dbID,
  -disease_id => $disease->dbID,
  -allelic_requirement => 'monoallelic_autosomal',
  -mutation_consequence => 'cis-regulatory or promotor mutation',
  -adaptor => $gfda,
);
$gfd = $gfda->store($gfd, $user);
ok($gfd->allelic_requirement eq 'monoallelic_autosomal', 'store allelic_requirement');
ok($gfd->mutation_consequence eq 'cis-regulatory or promotor mutation', 'store mutation_consequence');
ok($gfd->get_Disease->name eq 'KABUKI SYNDROME', 'store disease name');
ok($gfd->get_GenomicFeature->gene_symbol eq 'P3H1', 'store gene symbol');
my $gfd_logs = $gfd_log_adaptor->fetch_all_by_GenomicFeatureDisease($gfd);
my ($gfd_log) = grep {$_->action eq 'create'} @$gfd_logs;
ok($gfd_log->allelic_requirement eq 'monoallelic_autosomal', 'from log table: allelic_requirement');
ok($gfd_log->mutation_consequence eq 'cis-regulatory or promotor mutation', 'from log table: mutation_consequence');
ok($gfd_log->get_Disease->name eq 'KABUKI SYNDROME', 'from log table: disease name');
ok($gfd_log->get_GenomicFeature->gene_symbol eq 'P3H1', 'from log table: gene symbol');

$gfd->allelic_requirement('monoallelic_X_hem');
$gfd->mutation_consequence('uncertain');
$gfd = $gfda->update($gfd, $user);
$gfd = $gfda->fetch_by_dbID($gfd->dbID);
ok($gfd->allelic_requirement eq 'monoallelic_X_hem', 'update allelic_requirement');
ok($gfd->mutation_consequence eq 'uncertain', 'update mutation_consequence');

$gfd_logs = $gfd_log_adaptor->fetch_all_by_GenomicFeatureDisease($gfd);
($gfd_log) = grep {$_->action eq 'update'} @$gfd_logs;
ok($gfd_log->allelic_requirement eq 'monoallelic_X_hem', 'from log table, after update: allelic_requirement');
ok($gfd_log->mutation_consequence eq 'uncertain', 'from log table, after update: mutation_consequence');

$multi->restore('gene2phenotype', 'genomic_feature_disease', 'genomic_feature_disease_log');

#fetch_by_dbID

my $dbID = 1401; 
$gfd = $gfda->fetch_by_dbID($dbID);
ok($gfd->dbID == $dbID, 'fetch_by_dbID');
ok($gfd->original_allelic_requirement eq 'mosaic', 'fetch_by_dbID originial allelic_requirement');
ok($gfd->allelic_requirement eq 'mosaic', 'fetch_by_dbID allelic_requirement');
ok($gfd->cross_cutting_modifier eq 'typically mosaic', 'fetch_by_dbID cross_cutting_modifier');
ok($gfd->original_mutation_consequence eq 'activating', 'fetch_by_dbID original_mutation_consequence');
ok($gfd->mutation_consequence eq 'altered gene product structure', 'fetch_by_dbID mutation_consequence');
ok($gfd->mutation_consequence_flag eq 'restricted mutation set', 'fetch_by_dbID mutation_consequence_flag');
ok($gfd->get_Disease->name eq 'MEGALENCEPHALY-CAPILLARY MALFORMATION-POLYMICROGYRIA SYNDROME, SOMATIC 3', 'fetch_by_dbID disease name');
ok($gfd->get_GenomicFeature->gene_symbol eq 'PIK3CA', 'fetch_by_dbID gene symbol');

$dbID = 1797; 
$gfd = $gfda->fetch_by_dbID($dbID);
ok($gfd->dbID == $dbID, 'fetch_by_dbID');
ok($gfd->original_allelic_requirement eq 'biallelic', 'fetch_by_dbID originial allelic_requirement');
ok($gfd->allelic_requirement eq 'biallelic_autosomal', 'fetch_by_dbID allelic_requirement');
ok($gfd->original_mutation_consequence eq 'all missense/in frame', 'fetch_by_dbID original_mutation_consequence');
ok($gfd->mutation_consequence eq 'altered gene product structure', 'fetch_by_dbID mutation_consequence');
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
$gfds = $gfda->fetch_all_by_GenomicFeature_constraints($genomic_feature, {'allelic_requirement' => 'biallelic_autosomal', 'mutation_consequence' => 'absent gene product'});
ok(scalar @$gfds == 1, 'fetch_all_by_GenomicFeature_constraints');

done_testing();
1;

