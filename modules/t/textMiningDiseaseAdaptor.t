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

use Data::Dumper;
use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $tmda = $g2pdb->get_TextMiningDiseaseAdaptor;

ok($tmda && $tmda->isa('Bio::EnsEMBL::G2P::DBSQL::TextMiningDiseaseAdaptor'), 'isa text_mining_disease_adaptor');

my $publication_adaptor = $g2pdb->get_PublicationAdaptor;

my $publications = $publication_adaptor->fetch_all;
foreach my $publication (@$publications) {
  my $pmid = $publication->pmid;
  $tmda->store_all_by_Publication($publication);
}

done_testing();
1;
