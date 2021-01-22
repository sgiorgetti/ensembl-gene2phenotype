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
use Spreadsheet::Read;
use Bio::EnsEMBL::G2P::LocusGenotypeMechanism;
use Bio::EnsEMBL::G2P::LGMPanel;
use Bio::EnsEMBL::G2P::LGMPanelDisease;
use Bio::EnsEMBL::G2P::LGMPublication;
my $config = {};

GetOptions(
  $config,
  'registry_file=s',
  'import_file=s',
  'panel=s',
  'email=s',
) or die "Error: Failed to parse command line arguments\n";

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);
my $panel_name = $config->{panel};

my $species = 'human';
my $allele_feature_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'AlleleFeature');
my $transcript_allele_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'TranscriptAllele');
my $gene_feature_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GeneFeature');
my $locus_genotype_mechanism_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'LocusGenotypeMechanism');
my $LGM_panel_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'LGMPanel');
my $LGM_panel_disease_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'LGMPanelDisease');

my $LGM_publication_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'LGMPublication');

my $panel_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'Panel');
my $panel = $panel_adaptor->fetch_by_name($panel_name);

my $user_email = $config->{email};
my $user_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'User');
my $user = $user_adaptor->fetch_by_email($user_email);

my $gf_adaptor               = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeature');
my $disease_adaptor          = $registry->get_adaptor($species, 'gene2phenotype', 'Disease');
my $gfd_adaptor              = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDisease');
my $gfd_action_adaptor       = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseaseAction');
my $attrib_adaptor           = $registry->get_adaptor($species, 'gene2phenotype', 'Attribute');
my $publication_adaptor      = $registry->get_adaptor($species, 'gene2phenotype', 'Publication');

my $panel_attrib_id = $attrib_adaptor->attrib_id_for_value($panel_name);

my $dbh = $registry->get_DBAdaptor($species, 'gene2phenotype')->dbc->db_handle;

my $file = $config->{import_file};
die "Data file $file doesn't exist" if (!-e $file);
my $book  = ReadData($file);
my $sheet = $book->[1];
my @rows = Spreadsheet::Read::rows($sheet);
foreach my $row (@rows) {
  my ($gene, $disease_name, $variant, $pmid) = @$row;
  next if ($gene =~ /^Gene/);

  my @pmids = get_pmids($pmid);

  my $variant_id = "$gene:$variant";
  my $allele_features = $allele_feature_adaptor->fetch_all_by_name($variant_id);

  my $gf = $gf_adaptor->fetch_by_gene_symbol($gene);
  my $disease_list = $disease_adaptor->fetch_all_by_name($disease_name);
  my @sorted_disease_list = sort {$a->dbID <=> $b->dbID} @$disease_list;
  my $disease = $sorted_disease_list[0]; 
  if ($gf && $disease) {
    my $gfd = $gfd_adaptor->fetch_by_GenomicFeature_Disease_panel_id($gf, $disease, $panel_attrib_id);
    my $confidence_category = $gfd->confidence_category;
    my $gfd_actions = $gfd_action_adaptor->fetch_all_by_GenomicFeatureDisease($gfd);
    if (scalar @{$gfd_actions} == 1) {
      my $gfd_action = $gfd_actions->[0];
      my $allelic_requirement = $gfd_action->allelic_requirement || 'NA';
      my $mutation_consequence = $gfd_action->mutation_consequence || 'NA';
      foreach my $allele_feature (@{$allele_features}) {
        my $allele_feature_id = $allele_feature->dbID();
        my $locus_genotype_mechanism = $locus_genotype_mechanism_adaptor->fetch_by_locus_id_locus_type_genotype_mechanism($allele_feature_id, 'allele', $allelic_requirement, $mutation_consequence);
        if (!defined  $locus_genotype_mechanism) {
          $locus_genotype_mechanism = Bio::EnsEMBL::G2P::LocusGenotypeMechanism->new(
            -adaptor => $locus_genotype_mechanism_adaptor,
            -locus_type => 'allele',
            -locus_id => $allele_feature_id,
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
            -user_id => $user->dbID,
          );
          $lgm_panel = $LGM_panel_adaptor->store($lgm_panel);
        }
        foreach my $pmid (@pmids) {
          my $publication = $publication_adaptor->fetch_by_PMID($pmid);
          if (!$publication) {
            $publication = Bio::EnsEMBL::G2P::Publication->new(
              -pmid => $pmid,
            );
            $publication = $publication_adaptor->store($publication);
          }
          my $lgm_publication = $LGM_publication_adaptor->fetch_by_LocusGenotypeMechanism_Publication($locus_genotype_mechanism, $publication);
          if (!defined $lgm_publication) {
            $lgm_publication = Bio::EnsEMBL::G2P::LGMPublication->new(
              -adaptor => $LGM_publication_adaptor,
              -locus_genotype_mechanism_id => $locus_genotype_mechanism->dbID,
              -publication_id => $publication->dbID,
              -user_id => $user->dbID,
            );
            $lgm_publication = $LGM_publication_adaptor->store($lgm_publication);
          }
        }
        my $lgm_panel_disease = $LGM_panel_disease_adaptor->fetch_by_LGMPanel_Disease($lgm_panel, $disease);
        if (!defined $lgm_panel_disease) {
          $lgm_panel_disease = Bio::EnsEMBL::G2P::LGMPanelDisease->new(
            -adaptor => $LGM_panel_disease_adaptor,
            -LGM_panel_id => $lgm_panel->dbID,
            -default_name => 1,
            -disease_id => $disease->dbID,
            -user_id => $user->dbID,
          );
          $lgm_panel_disease = $LGM_panel_disease_adaptor->store($lgm_panel_disease);
        }
      }
    }
  } else {
    print "$gene $disease_name\n";
  }
}

sub get_pmids {
  my $pmids_string = shift;
  my @pubmed_ids = ();
  foreach my $pmid (split(/;|,/, $pmids_string)) {
    $pmid =~ s/^\s+|\s+$//g;
    push @pubmed_ids, $pmid;
  }
  return @pubmed_ids;
}

