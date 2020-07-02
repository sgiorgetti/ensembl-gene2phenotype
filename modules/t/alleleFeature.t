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
use Bio::EnsEMBL::G2P::AlleleFeature;
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $allele_feature_adaptor = $g2pdb->get_AlleleFeatureAdaptor;

my $seq_region_name = '4';
my $seq_region_start = 1804392; 
my $seq_region_end = 1804392;
my $seq_region_strand = 1;
my $name = 'FGFR3:p.Gly380Arg';
my $ref_allele = 'G';
my $alt_allele = 'C';
my $hgvs_genomic = 'NC_000004.12:g.1804392G>C';

my $af = Bio::EnsEMBL::G2P::AlleleFeature->new(
  -seq_region_name => $seq_region_name,
  -seq_region_start => $seq_region_start, 
  -seq_region_end => $seq_region_end,
  -seq_region_strand => $seq_region_strand,
  -name => $name,
  -ref_allele => $ref_allele,
  -alt_allele => $alt_allele,
  -hgvs_genomic => $hgvs_genomic,
  -adaptor => $allele_feature_adaptor,
);

ok($af->seq_region_name eq $seq_region_name, 'get/set seq_region_name'); 
ok($af->seq_region_start eq $seq_region_start, 'get/set seq_region_start'); 
ok($af->seq_region_end eq $seq_region_end, 'get/set seq_region_end'); 
ok($af->seq_region_strand eq $seq_region_strand, 'get/set seq_region_strand'); 
ok($af->name eq $name, 'get/set name'); 
ok($af->ref_allele eq $ref_allele, 'get/set ref_allele'); 
ok($af->alt_allele eq $alt_allele, 'get/set alt_allele'); 
ok($af->hgvs_genomic eq $hgvs_genomic, 'get/set hgvs_genomic'); 

done_testing();
1;
