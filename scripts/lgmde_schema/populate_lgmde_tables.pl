# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use DBI;
use Getopt::Long;
use FileHandle;
use Data::Dumper;
my $config = {};
GetOptions(
  $config,
  'registry_file=s',
) or die "Error: Failed to parse command line arguments\n";
die ('A registry file is required (--registry_file)') unless (defined($config->{registry_file}));

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);

my $species = 'human';
my $user_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'user');
my $panel_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'Panel');
my $gfd_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDisease');
my $gfd_log_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseaseLog');
my $gfda_log_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseaseActionLog');
my $gfd_phenotype_log_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GFDPhenotypeLog');

my $placeholder_feature_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'PlaceholderFeature');
my $locus_genotype_mechanism_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'LocusGenotypeMechanism');
my $LGM_panel_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'LGMPanel'); 
my $LGM_panel_disease_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'LGMPanelDisease');
my $LGM_phenotype_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'LGMPhenotype');
my $LGM_publication_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'LGMPublication');

# Populate tables:
#  - locus_genotype_mechanism
#  - gene_feature, allele_feature, placeholder_feature
#  - LGM_panel
#  - LGM_panel_disease, 
#   - where should we store disease name synonyms

# 1) truncate tables: locus_genotype_mechanism, allele_feature, placeholder_feature, LGM_panel, LGM_panel_disease 
truncate_tables();

# 2) populate gene_feature

populate_gene_feature();

# 3) populate locus_genotype_mechanism from old schema tables: genomic_feature_disease, genomic_feature_disease, genomic_feature_disease_action_log
populate_lgmde_tables();

sub truncate_tables {
  my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;
  foreach my $table (qw/locus_genotype_mechanism allele_feature gene_feature placeholder_feature LGM_panel LGM_panel_disease LGM_phenotype LGM_publication/) {
    $dbh->do(qq{TRUNCATE TABLE $table;}) or die $dbh->errstr;
  }
}

sub populate_gene_feature {
  my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;
  $dbh->do(qq{INSERT INTO gene_feature(gene_feature_id, gene_symbol, hgnc_id, mim, ensembl_stable_id) SELECT genomic_feature_id, gene_symbol, hgnc_id, mim, ensembl_stable_id FROM genomic_feature;}) or die $dbh->errstr;

}

sub populate_lgmde_tables {

  my $panels = $panel_adaptor->fetch_all;

  foreach my $panel (sort {$a->name cmp $b->name} @$panels) {
    my $panel_name = $panel->name;
    my $panel_id = $panel->dbID;
    next if ($panel_name eq 'Demo');
    my $gfds = $gfd_adaptor->fetch_all_by_panel($panel->name);
    foreach my $gfd (@$gfds) {
      my $gene_symbol = $gfd->get_GenomicFeature->gene_symbol;
      my $genomic_feature_id = $gfd->get_GenomicFeature->dbID;
      my $disease = $gfd->get_Disease;
      my $disease_name = $disease->name;
      my $disease_id = $disease->dbID;

      my $gfd_disease_synonyms = $gfd->get_all_GFDDiseaseSynonyms;
      my $gfd_publications = $gfd->get_all_GFDPublications;
      my $gfd_phenotypes = $gfd->get_all_GFDPhenotypes;

      my $actions = $gfd->get_all_GenomicFeatureDiseaseActions;
      my $confidence_category = $gfd->confidence_category;

      my $gfd_logs = $gfd_log_adaptor->fetch_all_by_GenomicFeatureDisease($gfd);
      my @created = grep {$_->action eq 'create'} @{$gfd_logs};

      foreach my $action (@$actions) {
        my $allelic_requirement = $action->allelic_requirement;
        my $mutation_consequence = $action->mutation_consequence;
        next unless ($allelic_requirement && $mutation_consequence);
        my $gfda_logs = $gfda_log_adaptor->fetch_all_by_GenomicFeatureDiseaseAction($action);
        my @gfda_created = grep {$_->action eq 'create'} @{$gfda_logs};
        if (scalar @gfda_created != 1) {
          die "no or more than one gfda\n";
        }
        my $gfda_log = $gfda_created[0];
        my $user_id = $gfda_log->user_id;
        my $created = $gfda_log->created;

        my $locus_type = 'gene';
        my $locus_feature_id = $genomic_feature_id;

        # if restricted mutation set add a placeholder
        if ($gfd->restricted_mutation_set) {
          $locus_type = 'placeholder';
          my $placeholder_feature = $placeholder_feature_adaptor->fetch_by_gene_feature_id_disease_id_panel_id($genomic_feature_id, $disease_id, $panel_id);
          if (!defined $placeholder_feature) {
            $placeholder_feature = Bio::EnsEMBL::G2P::PlaceholderFeature->new(
              -adaptor => $placeholder_feature_adaptor,
              -gene_feature_id => $genomic_feature_id,
              -disease_id => $disease_id,
              -panel_id => $panel_id
            );
            $placeholder_feature = $placeholder_feature_adaptor->store($placeholder_feature);
          }
          $locus_feature_id = $placeholder_feature->dbID;
        }

        my $locus_genotype_mechanism = $locus_genotype_mechanism_adaptor->fetch_by_locus_id_locus_type_genotype_mechanism($locus_feature_id, $locus_type, $allelic_requirement, $mutation_consequence);

        if (!defined  $locus_genotype_mechanism) {
          $locus_genotype_mechanism = Bio::EnsEMBL::G2P::LocusGenotypeMechanism->new(
            -adaptor => $locus_genotype_mechanism_adaptor,
            -locus_type => $locus_type,
            -locus_id => $locus_feature_id,
            -genotype => $allelic_requirement,
            -mechanism => $mutation_consequence,
          );
          $locus_genotype_mechanism = $locus_genotype_mechanism_adaptor->store($locus_genotype_mechanism);
        }
        my $lgm_panel = $LGM_panel_adaptor->fetch_by_LocusGenotypeMechanism_Panel($locus_genotype_mechanism, $panel);
        if (!defined $lgm_panel) {
          $lgm_panel = Bio::EnsEMBL::G2P::LGMPanel->new(
            -adaptor => $LGM_panel_adaptor,
            -locus_genotype_mechanism_id => $locus_genotype_mechanism->dbID,
            -panel_id => $panel->dbID,
            -confidence_category => $confidence_category,
            -user_id => $user_id,
            -created => $created,
          );
          $lgm_panel = $LGM_panel_adaptor->store($lgm_panel);
        }

       # disease names and disease name synonyms 
        my $lgm_panel_disease = $LGM_panel_disease_adaptor->fetch_by_LGMPanel_Disease($lgm_panel, $disease);
        if (!defined $lgm_panel_disease) {
          $lgm_panel_disease = Bio::EnsEMBL::G2P::LGMPanelDisease->new(
            -adaptor => $LGM_panel_disease_adaptor,
            -LGM_panel_id => $lgm_panel->dbID,
            -disease_id => $disease_id,
            -default_name => 1,
            -user_id => $user_id,
            -created => $created,
          );
          $lgm_panel_disease = $LGM_panel_disease_adaptor->store($lgm_panel_disease);
        }

        foreach my $gfd_disease_synonym (@{$gfd_disease_synonyms}) {
          my $disease_synonym_id = $gfd_disease_synonym->disease_id;
          $lgm_panel_disease = $LGM_panel_disease_adaptor->fetch_by_lgm_panel_id_disease_id($lgm_panel->dbID, $disease_synonym_id); 
          if (!defined $lgm_panel_disease) {
            $lgm_panel_disease = Bio::EnsEMBL::G2P::LGMPanelDisease->new(
              -adaptor => $LGM_panel_disease_adaptor,
              -LGM_panel_id => $lgm_panel->dbID,
              -disease_id => $disease_synonym_id,
              -user_id => $user_id,
              -created => $created,
            );
            $lgm_panel_disease = $LGM_panel_disease_adaptor->store($lgm_panel_disease);
          }
        }

        foreach my $gfd_publication (@{$gfd_publications}) {
          my $publication = $gfd_publication->get_Publication;
          my $lgm_publication = $LGM_publication_adaptor->fetch_by_LocusGenotypeMechanism_Publication($locus_genotype_mechanism, $publication);
          if (!defined $lgm_publication) {
            $lgm_publication = Bio::EnsEMBL::G2P::LGMPublication->new(
              -adaptor => $LGM_publication_adaptor,
              -locus_genotype_mechanism_id => $locus_genotype_mechanism->dbID,
              -publication_id => $publication->dbID,
              -user_id => $user_id,
              -created => $created,
            );
            $lgm_publication = $LGM_publication_adaptor->store($lgm_publication);
          }
        }
        foreach my $gfd_phenotype (@{$gfd_phenotypes}) {
          my $phenotype = $gfd_phenotype->get_Phenotype;
          my $lgm_phenotype = $LGM_phenotype_adaptor->fetch_by_LocusGenotypeMechanism_Phenotype($locus_genotype_mechanism, $phenotype);
          if (!defined $lgm_phenotype) {
            my $phenotype_created_time = $created;
            my $phenotype_created_user_id = $user_id;
            my $gfd_phenotype_logs = $gfd_phenotype_log_adaptor->fetch_all_by_GenomicFeatureDiseasePhenotype($gfd_phenotype);
            my @gfd_phenotype_created = grep {$_->action eq 'create'} @{$gfd_phenotype_logs};
            if (scalar @gfd_phenotype_created > 1) {
              my $gfd_phenotype_log = $gfd_phenotype_created[0];
              $phenotype_created_user_id = $gfd_phenotype_log->user_id;
              $phenotype_created_time = $gfd_phenotype_log->created;
            }
            $lgm_phenotype = Bio::EnsEMBL::G2P::LGMPhenotype->new(
              -adaptor => $LGM_phenotype_adaptor,
              -locus_genotype_mechanism_id => $locus_genotype_mechanism->dbID,
              -phenotype_id => $phenotype->dbID,
              -user_id => $phenotype_created_user_id,
              -created => $phenotype_created_time,
            );
            $lgm_phenotype = $LGM_phenotype_adaptor->store($lgm_phenotype);
          }
        }
      }
    }
  }
}


