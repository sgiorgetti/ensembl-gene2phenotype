use strict;
use warnings;

use Spreadsheet::Read;
use Text::CSV;
use Bio::EnsEMBL::Registry;
use DBI;
use Getopt::Long;
use G2P::Registry;
use FileHandle;
my $config = {};

GetOptions(
  $config,
  'registry_file=s',
  'email=s',
  'import_file=s',
) or die "Error: Failed to parse command line arguments\n";

die ('A registry file is required (--registry_file)') unless (defined($config->{registry_file}));

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle; 
my $gfda = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');
my $gfdaa = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseaseAction');
my $gfd_publication_adaptor =  $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseasePublication');
my $gfd_phenotype_adaptor =  $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseasePhenotype');
my $gfd_organ_adaptor =  $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseaseOrgan');
my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'User');

# create new panel
my $user = $user_adaptor->fetch_by_email($config->{email});
my $ear_panel_id = 39;

#remove_data_from_dd_panel();
#populate_from_dd_panel();

sub populate_from_dd_panel {
  my $gfds = $gfda->fetch_all_by_panel('DD');
  foreach my $gfd (@$gfds) {
    my $disease_name = $gfd->get_Disease->name;
    if ($disease_name =~ /DEAFNESS/i) {
      my $gfd_organs = $gfd->get_all_GFDOrgans;
      my @organs = map {$_->get_Organ->name} @$gfd_organs;
      my $gene_symbol = $gfd->get_GenomicFeature->gene_symbol;
      my $gfd_id = $gfd->dbID;
      my $disease_confidence_attrib = $gfd->DDD_category_attrib; 

#      my $new_gfd = $gfda->fetch_by_GenomicFeature_Disease_panel_id($gfd->get_GenomicFeature, $gfd->get_Disease, $ear_panel_id);

      my $new_gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
        -genomic_feature_id => $gfd->get_GenomicFeature->dbID,
        -disease_id => $gfd->get_Disease->dbID,
        -panel_attrib => $ear_panel_id,
        -DDD_category_attrib => $disease_confidence_attrib,
        -adaptor => $gfda,
      );
      $new_gfd = $gfda->store($new_gfd, $user); 
      my $new_gfd_id = $new_gfd->dbID;
      my $gfdas = $gfd->get_all_GenomicFeatureDiseaseActions;
      foreach my $gfd_action (@$gfdas) {
        my $ar_attrib = $gfd_action->allelic_requirement_attrib;
        my $mc_attrib = $gfd_action->mutation_consequence_attrib;
        my $new_GFD_action = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseAction->new(
          -genomic_feature_disease_id => $new_gfd_id,
          -allelic_requirement_attrib => $ar_attrib,
          -mutation_consequence_attrib => $mc_attrib,
          -user_id => undef,
        );
        $new_GFD_action = $gfdaa->store($new_GFD_action, $user);
      }
      
      my $gfd_publications = $gfd->get_all_GFDPublications;
      foreach my $gfd_publication (@$gfd_publications) {
        my $publication_db_id = $gfd_publication->get_Publication->dbID;
        my $GFDPublication = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication->new(
          -genomic_feature_disease_id => $new_gfd_id,
          -publication_id => $publication_db_id,
          -adaptor => $gfd_publication_adaptor,
        );
        $gfd_publication_adaptor->store($GFDPublication);
      }

      my $gfd_phenotypes = $gfd->get_all_GFDPhenotypes;
      foreach my $gfd_phenotype (@$gfd_phenotypes) {
        my $phenotype_db_id = $gfd_phenotype->get_Phenotype->dbID;
        my $GFDPhenotype = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePhenotype->new(
          -genomic_feature_disease_id => $new_gfd_id,
          -phenotype_id => $phenotype_db_id,
          -adaptor => $gfd_phenotype_adaptor,
        );
        $gfd_phenotype_adaptor->store($GFDPhenotype);
      }

      foreach my $gfd_organ (@$gfd_organs) {
        my $organ_db_id = $gfd_organ->get_Organ->dbID;
        my $GFDOrgan = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseOrgan->new(
          -genomic_feature_disease_id => $new_gfd_id,
          -organ_id => $organ_db_id,
          -adaptor => $gfd_organ_adaptor,
        );
        $gfd_organ_adaptor->store($GFDOrgan);
      }
    }
  }
}

sub remove_data_from_dd_panel {
  my $gfds = $gfda->fetch_all;
  foreach my $gfd (@$gfds) {
    my $disease_name = $gfd->get_Disease->name;
    if ($disease_name =~ /DEAFNESS/i) {
      my $gfd_organs = $gfd->get_all_GFDOrgans;
      my @organs = map {$_->get_Organ->name} @$gfd_organs;
      if (scalar @organs == 1 && $organs[0] eq 'Ear') {   
        my $gene_symbol = $gfd->get_GenomicFeature->gene_symbol;
        my $gfd_id = $gfd->dbID;
        $dbh->do(qq{UPDATE genomic_feature_disease SET panel_attrib='$ear_panel_id' WHERE genomic_feature_disease_id=$gfd_id;}) or die $dbh->errstr;  
      }
    }
  }
}

