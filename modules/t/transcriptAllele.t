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
use Bio::EnsEMBL::G2P::TranscriptAllele;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $transcript_allele_adaptor = $g2pdb->get_TranscriptAlleleAdaptor;

my $allele_feature_id = 20;
my $gene_feature_id = 1291;
my $transcript_stable_id = 'ENST00000481110.6';
my $consequence_types = 'missense_variant';
my $cds_start = 1142; 
my $cds_end = 1142;
my $cdna_start = 1403;
my $cdna_end = 1403;
my $translation_start = 381;
my $translation_end = 381;
my $codon_allele_string = 'gTg/gAg';
my $pep_allele_string = 'V/E';


my $ta = Bio::EnsEMBL::G2P::TranscriptAllele->new(
  -allele_feature_id => $allele_feature_id,
  -gene_feature_id => $gene_feature_id,
  -transcript_stable_id => $transcript_stable_id,
  -consequence_types => $consequence_types,
  -cds_start => $cds_start,
  -cds_end => $cds_end,
  -cdna_start => $cdna_start,
  -cdna_end => $cdna_end,
  -translation_start => $translation_start,
  -translation_end => $translation_end,
  -codon_allele_string => $codon_allele_string,
  -pep_allele_string => $pep_allele_string,
  -adaptor => $transcript_allele_adaptor,
);

ok($ta->allele_feature_id eq $allele_feature_id, 'get/set allele_feature_id'); 
ok($ta->gene_feature_id eq $gene_feature_id, 'get/set gene_feature_id'); 
ok($ta->transcript_stable_id eq $transcript_stable_id, 'get/set transcript_stable_id'); 
ok($ta->consequence_types eq $consequence_types, 'get/set consequence_types'); 
ok($ta->cds_start eq $cds_start, 'get/set cds_start'); 
ok($ta->cds_end eq $cds_end, 'get/set cds_end'); 
ok($ta->cdna_start eq $cdna_start, 'get/set cdna_start'); 
ok($ta->cdna_end eq $cdna_end, 'get/set cdna_end'); 
ok($ta->translation_start eq $translation_start, 'get/set translation_start'); 
ok($ta->translation_end eq $translation_end, 'get/set translation_end'); 
ok($ta->codon_allele_string eq $codon_allele_string, 'get/set codon_allele_string'); 
ok($ta->pep_allele_string eq $pep_allele_string, 'get/set pep_allele_string'); 

done_testing();
1;
