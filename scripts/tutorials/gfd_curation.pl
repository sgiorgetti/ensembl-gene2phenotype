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

use Bio::EnsEMBL::Registry;
use Getopt::Long;
my $config = {};
GetOptions(
  $config,
  'registry_file=s',
) or die "Error: Failed to parse command line arguments\n";

die ('A registry file is required (--registry_file)') unless (defined($config->{registry_file}));

# Instatiate registry object 
my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);

my $species = 'human';
# Create adaptors
my $disease_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'Disease');
my $gf_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeature');
my $gfd_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDisease');
my $gfd_panel_log_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseasePanelLog');

# fetch GenomicFeature
my $gf = $gf_adaptor->fetch_by_gene_symbol('GJA1');

# fetch Disease
my $disease = $disease_adaptor->fetch_by_name('HALLERMANN-STREIFF SYNDROME');

# fetch GFD gene symbol: GJA1, allelic requirement: biallelic, mutation consequence: all missense/in frame, disease: HALLERMANN-STREIFF SYNDROME 
my $gfds = $gfd_adaptor->fetch_all_by_GenomicFeature_constraints($gf, {allelic_requirement => 'biallelic', mutation_consequence => 'all missense/in frame', disease_id => $disease->dbID });
my $gfd = $gfds->[0];

my $allelic_requirement = $gfd->allelic_requirement;
my $allelic_requirement_attrib = $gfd->allelic_requirement_attrib;

my $mutation_consequence = $gfd->mutation_consequence;
my $mutation_consequence_attrib = $gfd->mutation_consequence_attrib;

print "Allelic requirement: $allelic_requirement, allelic requirement attrib: $allelic_requirement_attrib, Mutation consequence: $mutation_consequence, mutatation consequence attrib: $mutation_consequence_attrib.\n";

my $panels = $gfd->panels;
print 'Panels: ', join(', ', @{$panels}), "\n";

# get all GenomicFeatureDiseasePanels
my $gfd_panels = $gfd->get_all_GFDPanels;

foreach my $gfd_panel (@{$gfd_panels}) {
  my $panel = $gfd_panel->panel;
  my $panel_attrib = $gfd_panel->panel_attrib;
  my $confidence_category = $gfd_panel->confidence_category; 
  my $confidence_category_attrib = $gfd_panel->confidence_category_attrib; 
  my $is_visible = $gfd_panel->is_visible;
  print "Panel $panel, panel attrib $panel_attrib, Confidence category: $confidence_category, confidence category attrib: $confidence_category_attrib, is visible: $is_visible\n";

  # get all log entries
  my $logs = $gfd_panel_log_adaptor->fetch_all_by_GenomicFeatureDiseasePanel($gfd_panel);
  foreach my $log (@$logs) {
    my $created = $log->created; 
    my $user_id = $log->user_id;
    my $action = $log->action;
    print "    GenomicFeatureDiseasePanelLog: created: $created, user id: $user_id, action: $action\n";
  }
}

# get all publications

my $gfd_publications = $gfd->get_all_GFDPublications;
print 'Publications: ', scalar @$gfd_publications, "\n"; 

my $publication_comments = 0;
foreach my $gfd_publication (@$gfd_publications) {
  $publication_comments += scalar @{$gfd_publication->get_all_GFDPublicationComments};
}
print "Publication comments: $publication_comments\n";

my $gfd_phenotypes = $gfd->get_all_GFDPhenotypes;
print 'Phenotypes: ', scalar @$gfd_phenotypes, "\n";

my $phenotype_comments = 0;
foreach my $gfd_phenotype (@$gfd_phenotypes) {
  $phenotype_comments += scalar @{$gfd_phenotype->get_all_GFDPhenotypeComments};
}
print "Phenotype comments: $phenotype_comments\n";

my $gfd_organs = $gfd->get_all_GFDOrgans;
print 'Organs: ', scalar @$gfd_organs, "\n";

my $gfd_comments = $gfd->get_all_GFDComments;
print 'Comments: ', scalar @$gfd_comments, "\n";

my $gfd_disease_synonyms = $gfd->get_all_GFDDiseaseSynonyms;
print 'Disease synonyms: ', scalar @$gfd_disease_synonyms, "\n";


