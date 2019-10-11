use strict;
use warnings;

use DBI;
use FileHandle;
use Bio::EnsEMBL::Registry;

my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all('/Users/anja/Documents/G2P/ensembl.registry.testdb.oct2019');

my $GFD_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');
my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'User');
my $phenotype_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'Phenotype'); 
my $GFDPhenotype_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseasePhenotype');

my $email = 'user1@email.com';
my $user = $user_adaptor->fetch_by_email($email);
my $GFD_id = 1418;
my $GFD = $GFD_adaptor->fetch_by_dbID($GFD_id);
my $phenotype_id = 5; 
my $GFDP = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePhenotype->new(
  -genomic_feature_disease_id => $GFD_id,
  -phenotype_id => $phenotype_id,
  -adaptor => $GFDPhenotype_adaptor,
);
$GFDPhenotype_adaptor->store($GFDP, $user);

