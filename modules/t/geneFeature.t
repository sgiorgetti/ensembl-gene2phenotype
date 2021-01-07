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

my $gfa = $g2pdb->get_GeneFeatureAdaptor;

my $seq_region_name = '12';
my $seq_region_start = 47972967; 
my $seq_region_end = 48004554;
my $seq_region_strand = -1;
my $gene_symbol = 'COL2A1';
my $hgnc_id = 2200; 
my $mim = '120140';
my $ensembl_stable_id = 'ENSG00000139219'; 

my $gf = Bio::EnsEMBL::G2P::GeneFeature->new(
  -seq_region_name => $seq_region_name,
  -seq_region_start => $seq_region_start, 
  -seq_region_end => $seq_region_end,
  -seq_region_strand => $seq_region_strand,
  -gene_symbol => $gene_symbol,
  -hgnc_id => $hgnc_id,
  -mim => $mim,
  -ensembl_stable_id => $ensembl_stable_id,
  -adaptor => $gfa,
);

ok($gf->seq_region_name eq $seq_region_name, 'get/set seq_region_name'); 
ok($gf->seq_region_start eq $seq_region_start, 'get/set seq_region_start'); 
ok($gf->seq_region_end eq $seq_region_end, 'get/set seq_region_end'); 
ok($gf->seq_region_strand eq $seq_region_strand, 'get/set seq_region_strand'); 
ok($gf->hgnc_id eq $hgnc_id, 'get/set hgnc_id'); 
ok($gf->gene_symbol eq $gene_symbol, 'get/set gene_symbol'); 
ok($gf->mim eq $mim, 'get/set mim');
ok($gf->ensembl_stable_id eq $ensembl_stable_id, 'get/set ensembl_stable_id');

done_testing();
1;
