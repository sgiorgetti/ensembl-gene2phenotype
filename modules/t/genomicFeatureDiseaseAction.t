use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::G2P::GenomicFeatureDiseaseAction;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfdaa = $g2pdb->get_GenomicFeatureDiseaseActionAdaptor;

my $genomic_feature_disease_id = 49;
my $allelic_requirement_attrib = '14';
my $mutation_consequence_attrib = '24';

my $gfda = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseAction->new(
  -genomic_feature_disease_id => $genomic_feature_disease_id,
  -allelic_requirement_attrib => $allelic_requirement_attrib,
  -mutation_consequence_attrib => $mutation_consequence_attrib,  
  -adaptor => $gfdaa,
);

ok($gfda->genomic_feature_disease_id == $genomic_feature_disease_id, 'genomic_feature_disease_id');
ok($gfda->allelic_requirement_attrib eq $allelic_requirement_attrib, 'allelic_requirement_attrib');
ok($gfda->allelic_requirement eq 'monoallelic', 'allelic_requirement');
ok($gfda->mutation_consequence_attrib eq $mutation_consequence_attrib, 'mutation_consequence_attrib');
ok($gfda->mutation_consequence eq 'dominant negative', 'mutation_consequence');

done_testing();
1;
