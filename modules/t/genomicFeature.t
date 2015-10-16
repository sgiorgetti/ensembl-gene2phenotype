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

my $gfa = $g2pdb->get_GenomicFeatureAdaptor;

my $gene_symbol = 'COL2A1';
my $mim = '120140';
my $ensembl_stable_id = 'ENSG00000139219'; 

my $gf = Bio::EnsEMBL::G2P::GenomicFeature->new(
  -gene_symbol => $gene_symbol, 
  -mim => $mim,
  -ensembl_stable_id => $ensembl_stable_id,
  -adaptor => $gfa,
);

ok($gf->gene_symbol eq $gene_symbol, 'gene_symbol'); 
ok($gf->mim eq $mim, 'mim');
ok($gf->ensembl_stable_id eq $ensembl_stable_id, 'ensembl_stable_id');

done_testing();
1;
