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
use Bio::EnsEMBL::G2P::GenomicFeatureDiseaseLog;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfdla = $g2pdb->get_GenomicFeatureDiseaseLogAdaptor;

my $dbID = 2222;
my $genomic_feature_disease_id = 2683;
my $genomic_feature_id = 907;
my $allelic_requirement_attrib = '3';
my $allelic_requirement = 'biallelic';
my $mutation_consequence_attrib = '22';
my $mutation_consequence = 'all missense/in frame';
my $disease_id = 3438;
my $user_id = 10;
my $action = 'create';

my $gfdl = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseLog->new(
  -genomic_feature_disease_id => $genomic_feature_disease_id,
  -genomic_feature_id => $genomic_feature_id,
  -disease_id => $disease_id,
  -allelic_requirement_attrib => $allelic_requirement_attrib,
  -mutation_consequence_attrib => $mutation_consequence_attrib,
  -user_id => $user_id,
  -action => $action,
  -adaptor => $gfdla,
);

ok($gfdl->genomic_feature_disease_id == $genomic_feature_disease_id, 'genomic_feature_disease_id');
ok($gfdl->genomic_feature_id == $genomic_feature_id, 'genomic_feature_id');
ok($gfdl->disease_id == $disease_id, 'disease_id');
ok($gfdl->allelic_requirement_attrib eq $allelic_requirement_attrib, 'allelic_requirement_attrib');
ok($gfdl->allelic_requirement eq $allelic_requirement, 'allelic_requirement');
ok($gfdl->mutation_consequence eq $mutation_consequence, 'mutation_consequence');
ok($gfdl->disease_id == $disease_id, 'disease_id');
ok($gfdl->action eq $action, 'action');
ok($gfdl->user_id == $user_id, 'user_id');
ok($gfdl->{adaptor} && $gfdl->{adaptor}->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseLogAdaptor'), 'isa GenomicFeatureDiseaseLogAdaptor');
done_testing();

1;
