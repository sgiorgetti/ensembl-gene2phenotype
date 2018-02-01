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
use Bio::EnsEMBL::G2P::GenomicFeatureDiseaseLog;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfdla = $g2pdb->get_GenomicFeatureDiseaseLogAdaptor;

my $dbID = 133;
my $genomic_feature_id = 59384;
my $disease_id = 326;
my $DDD_category_attrib = 32;
my $is_visible = 1;
my $panel = '38';
my $user_id = 1;
my $action = 'create';

my $gfdl = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseLog->new(
  -genomic_feature_id => $genomic_feature_id,
  -disease_id => $disease_id,
  -DDD_category_attrib => $DDD_category_attrib,
  -is_visible => $is_visible,
  -panel => $panel,
  -user_id => $user_id,
  -action => $action,
  -adaptor => $gfdla,
);

ok($gfdl->genomic_feature_id == $genomic_feature_id, 'genomic_feature_id');
ok($gfdl->disease_id == $disease_id, 'disease_id');
ok($gfdl->DDD_category_attrib == $DDD_category_attrib, 'DDD_category_attrib');
ok($gfdl->DDD_category eq 'confirmed DD gene', 'DDD_category');
ok($gfdl->is_visible == 1, 'is_visible');
ok($gfdl->panel eq $panel, 'panel');
ok($gfdl->action eq $action, 'action');
ok($gfdl->user_id == $user_id, 'user_id');
ok($gfdl->{adaptor} && $gfdl->{adaptor}->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseLogAdaptor'), 'isa GenomicFeatureDiseaseLogAdaptor');
done_testing();

1;
