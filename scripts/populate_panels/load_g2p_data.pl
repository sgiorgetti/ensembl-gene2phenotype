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

=head1 NAME

load_g2p_data.pl - imports new entries and annotations from a spreadsheet into the gene2phenotype database

=cut

use strict;
use warnings;

use Spreadsheet::Read;
use Text::CSV;
use Bio::EnsEMBL::Registry;
use DBI;
use Getopt::Long;
use FileHandle;
my $config = {};
GetOptions(
  $config,
  'registry_file=s',
  'email=s',
  'import_file=s',
  'panel=s',
) or die "Error: Failed to parse command line arguments\n";
die ('A registry file is required (--registry_file)') unless (defined($config->{registry_file}));

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);

my $species = 'human';
my $gf_adaptor               = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeature');
my $disease_adaptor          = $registry->get_adaptor($species, 'gene2phenotype', 'Disease');
my $gfd_adaptor              = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDisease');
my $gfd_panel_adaptor        = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseasePanel');
my $gfd_publication_adaptor  = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseasePublication');
my $gfd_organ_adaptor        = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseaseOrgan');
my $gfd_phenotype_adaptor    = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseasePhenotype');
my $publication_adaptor      = $registry->get_adaptor($species, 'gene2phenotype', 'Publication');
my $organ_adaptor            = $registry->get_adaptor($species, 'gene2phenotype', 'Organ');
my $phenotype_adaptor        = $registry->get_adaptor($species, 'gene2phenotype', 'Phenotype');
my $attrib_adaptor           = $registry->get_adaptor($species, 'gene2phenotype', 'Attribute');
my $user_adaptor             = $registry->get_adaptor($species, 'gene2phenotype', 'User');
my $gfd_comment_adaptor      = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseaseComment');

my $email = $config->{email};
my $user = $user_adaptor->fetch_by_email($email);
die "Couldn't fetch user for email $email" if (!defined $user);

# Add new entry to this panel
my $g2p_panel = $config->{panel};
my $panel_attrib_id = $attrib_adaptor->get_attrib('g2p_panel', $g2p_panel);
die "Couldn't fetch panel_attrib_id for panel $g2p_panel" if (!defined $g2p_panel);

my $supported_mc_values = {
  'all missense/inframe' => 'all missense/in frame',
};

my $file = $config->{import_file};
die "Data file $file doesn't exist" if (!-e $file);
my $book  = ReadData($file);
my $sheet = $book->[1];
my @rows = Spreadsheet::Read::rows($sheet);
my @header = ();
foreach my $row (@rows) {
  if ($row->[0] =~ /^gene symbol/) {
    @header = @$row;
    next;
  }
  my %data = map {$header[$_] => $row->[$_]} (0..$#header);

  my $gene_symbol = $data{'gene symbol'}; 
  my $gene_mim = $data{'gene mim'};
  my $disease_name = $data{'disease name'};
  my $disease_mim = $data{'disease mim'};
  my $DDD_category = $data{'DDD category'};
  my $allelic_requirement = $data{'allelic requirement'};
  my $mutation_consequence = $data{'mutation consequence'};
  my $panel = $data{'panel'};
  my $prev_symbols = $data{'prev symbols'};
  my $hgnc_id = $data{'hgnc id'};
  my $restricted_mutation_set = $data{'restricted mutation set'};
  my $add_after_review = $data{'add after review'};

  if (!$panel) {
    warn "No panel for gene $gene_symbol\n";
    next;
  }
  next if (!add_to_panel($panel));  

  my $gf = get_genomic_feature($gene_symbol, $prev_symbols);
  if (!$gf) {
    die "No genomic feature for $gene_symbol\n";
  }

  my $confidence_attrib = get_confidence_attrib($DDD_category);

  my $allelic_requirement_attrib = get_allelic_requirement_attrib($allelic_requirement);

  my $mutation_consequence_attrib = get_mutation_consequence_attrib($mutation_consequence);

  if (!$disease_name) {
    die "No disease name for $gene_symbol, $allelic_requirement, $mutation_consequence\n";
  }

  my $disease = get_disease($disease_name, $disease_mim);

  # Try to get existing entries with same gene symbol, allelic requirement and mutation consequence
  my $gfds = $gfd_adaptor->fetch_all_by_GenomicFeature_constraints(
    $gf,
    {
      'allelic_requirement_attrib' => $allelic_requirement_attrib,
      'mutation_consequence_attrib' => $mutation_consequence_attrib,
    }
  );

  if (scalar @$gfds == 0) { 
    # Entries with same gene symbol, allelic requirement and mutation consequence don't exist
    # Create new GenomicFeatureDiease and GenomicFeatureDiseasePanel
    my $gfd = create_gfd($gf->dbID, $disease->dbID, $allelic_requirement_attrib, $mutation_consequence_attrib);
    add_gfd_to_panel($gfd->dbID, $g2p_panel, $confidence_attrib);
    add_annotations($gfd, %data);
  } else {
    foreach my $gfd (@$gfds) {
      my $is_target_panel = grep {$g2p_panel eq $_} @{$gfd->panels};
      my $target_disease_id = $gfd->get_Disease->dbID;
      if ( $disease->dbID == $target_disease_id && $is_target_panel ) {
        # same disease and GFD is already in target panel
        update_gfd_panel($gfd, $g2p_panel, $confidence_attrib);
        add_annotations($gfd, %data);
        last;
      } elsif ($disease->dbID == $target_disease_id && !$is_target_panel) {
        # GFD already exists. Add GFD to target panel
        add_gfd_to_panel($gfd->dbID, $g2p_panel, $confidence_attrib);
        add_annotations($gfd, %data);
        last;
      } elsif ($disease->dbID != $target_disease_id && $is_target_panel) {
        warn(
          "Entry with same gene symbol ($gene_symbol), allelic requirement ($allelic_requirement) " .
          "and mutation consequence ($mutation_consequence) exists in target panel ($g2p_panel). " .
          "But disease names are different: " .
          "For exisiting entry: " . $gfd->get_Disease->name . ". For new entry: $disease_name\n"  
        );
      } else {
        my $g2p_panels = join(',',  @{$gfd->panels});
        warn(
          "Entry with same gene symbol ($gene_symbol), allelic requirement ($allelic_requirement) " .
          "and mutation consequence ($mutation_consequence) exists in a different panel(s) ($g2p_panels). " .
          "The disease names are different: " .
          "For exisiting entry: " . $gfd->get_Disease->name . ". For new entry: $disease_name\n"  
        );
      }
    } 
    if ($add_after_review) {
      my $gfd = create_gfd($gf->dbID, $disease->dbID, $allelic_requirement_attrib, $mutation_consequence_attrib);
      add_gfd_to_panel($gfd->dbID, $g2p_panel, $confidence_attrib);
      add_annotations($gfd, %data);
    }
  }
}

=head2 add_annotations
  Arg [1]    : GenomicFeatureDisease $gfd
  Arg [2]    : hash %data contains keys (column header) and values (column value) for one row in the
               input spreadsheet.
  Description: Add annotations from the input row for the given GenomicFeatureDisease.
  Returntype : 
  Exceptions : None
  Status     : Stable
=cut

sub add_annotations {
  my ($gfd, %data) = @_;

  my $phenotypes = $data{'phenotypes'};
  my $organs = $data{'organ specificity list'};
  my $pmids = $data{'pmids'};
  my $comments = $data{'comments'};

  add_publications($gfd, $pmids); 

  add_phenotypes($gfd, $phenotypes, $user);

  add_organ_specificity($gfd, $organs);
  
  add_comments($gfd, $comments, $user);

}

=head2 create_gfd
  Arg [1]    : Integer $gf_id GenomicFeature database id
  Arg [2]    : Integer $disease_id Disease database id
  Arg [3]    : Integer $allelic_requirement_attrib - Can be a single attrib id or comma separated list of attrib ids.
  Arg [4]    : Integer $mutation_consequence_attrib - Single attrib id
  Description: Create a new GenomicFeatureDisease entry.
  Returntype : 
  Exceptions : None
  Status     : Stable
=cut

sub create_gfd {
  my ($gf_id, $disease_id, $allelic_requirement_attrib, $mutation_consequence_attrib) = @_;
  
  my $gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
      -genomic_feature_id => $gf_id,
      -disease_id => $disease_id,
      -allelic_requirement_attrib => $allelic_requirement_attrib,
      -mutation_consequence_attrib => $mutation_consequence_attrib,
      -adaptor => $gfd_adaptor,
    );
  $gfd = $gfd_adaptor->store($gfd, $user);
  return $gfd;
}

=head2 add_gfd_to_panel
  Arg [1]    : Integer $gfd_id - GenomicFeatureDisease database id
  Arg [2]    : String $g2p_panel - Add GFD to this panel
  Arg [3]    : Integer $confidence_attrib - Single attrib id
  Description: Create a new GenomicFeatureDiseasePanel entry.
  Returntype : 
  Exceptions : None
  Status     : Stable
=cut

sub add_gfd_to_panel {
  my ($gfd_id, $g2p_panel, $confidence_attrib) = @_;
  my $gfd_panel =  Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel->new(
    -genomic_feature_disease_id => $gfd_id,
    -panel => $g2p_panel,
    -confidence_category_attrib => $confidence_attrib,
    -adaptor => $gfd_panel_adaptor,
  );
  $gfd_panel = $gfd_panel_adaptor->store($gfd_panel, $user); 
}

=head2 update_gfd_panel
  Arg [1]    : GenomicFeatureDisease $gfd
  Arg [2]    : String $g2p_panel - Add GFD to this panel
  Arg [3]    : Integer $confidence_attrib - Single attrib id
  Description: Update the confidence value for the GenomicFeatureDiseasePanel entry.
               Check if the confidence value is different before updating.
  Returntype : 
  Exceptions : None
  Status     : Stable
=cut

sub update_gfd_panel {
  my ($gfd, $g2p_panel, $confidence_attrib) = @_;
  my $gfd_panel = $gfd_panel_adaptor->fetch_by_GenomicFeatureDisease_panel($gfd, $g2p_panel);
  if (!$gfd_panel) {
    die "Could not get GenomicFeatureDiseasePanel for GFD with gene symbol " .
        $gfd->get_GenomicFeature->gene_symbol . " and disease name " .
        $gfd->get_Disease->name . " and panel $g2p_panel\n";
  }
  if ($gfd_panel->confidence_category_attrib ne $confidence_attrib) {
    $gfd_panel->confidence_category_attrib($confidence_attrib);
    $gfd_panel_adaptor->update($gfd_panel, $user); 
  }
}

=head2 add_to_panel
  Arg [1]    : String $panels - ';' or ',' separated list of panels provided by the user.
  Description: The list specifies all the panels to which the new entry needs to be added.
               The script is run for each panel separately and we check if the panel that
               has been passed to the script is included in the list.
  Returntype : 1 if the script argument panel is included in the panel list and 0 if not. 
  Exceptions : None
  Status     : Stable
=cut

sub add_to_panel {
  my $panels = shift;
  my $add = 0;
  foreach my $panel (split/;|,/, $panels) {
    $panel =~ s/\s+//g;
    if (lc $panel eq lc $g2p_panel) {
      return 1;
    }
  } 
  return $add;
}

=head2 get_genomic_feature
  Arg [1]    : String $gene_symbol - Gene symbol from the import file
  Arg [2]    : String $prev_symbols - ';' or ',' separated list of previously assigned gene symbols
               from the import file
  Description: Tries to get the GenomicFeature for the given gene symbol or previously assigned gene
               symbols
  Returntype : GenomicFeature or undef
  Exceptions : None
  Status     : Stable
=cut

sub get_genomic_feature {
  my $gene_symbol = shift;
  my $prev_symbols = shift;
  my @symbols = ();
  push @symbols, $gene_symbol;
  if ($prev_symbols) {
    foreach my $symbol (split/;|,/, $prev_symbols) {
      $symbol =~ s/^\s+|\s+$//g;
      push @symbols, $symbol;
    }
  }
  foreach my $symbol (@symbols) { 
    my $gf = $gf_adaptor->fetch_by_gene_symbol($symbol);
    if (!$gf) {
      $gf = $gf_adaptor->fetch_by_synonym($symbol);
    }
    return $gf if (defined $gf);
  }
  return undef;
}

=head2 get_disease
  Arg [1]    : String $diseaes_name - Disease name from the import file
  Arg [2]    : Integer $mim - OMIM disease number
  Description: First tries to get the Disease for the given disease name.
               Create a new Disease entry if it doesn't already exist.
  Returntype : Disease
  Exceptions : None
  Status     : Stable
=cut

sub get_disease {
  my $disease_name = shift;
  my $disease_mim = shift;
  $disease_name =~ s/"//g;
  $disease_name =~ s/^\s+|\s+$//g;
  my $disease_list = $disease_adaptor->fetch_all_by_name($disease_name);
  my @sorted_disease_list = sort {$a->dbID <=> $b->dbID} @$disease_list;
  my $disease = $sorted_disease_list[0]; 
    
  if (! defined $disease) {
    $disease = Bio::EnsEMBL::G2P::Disease->new(
      -name => $disease_name,
      -adaptor => $disease_adaptor,
    );
    $disease = $disease_adaptor->store($disease);
  }

  my $mim = $disease->mim;
  if (!defined $mim && $disease_mim && $disease_mim =~ /^\d+$/) {
    $disease->mim($disease_mim);
    $disease_adaptor->update($disease);
  }
  return $disease;
}

=head2 get_confidence_attrib

  Arg [1]    : String $confidence_category - Confidence category from the import file 
  Description: Get the confidence category attrib id for the given confidence
               category value.
  Returntype : String $confidence_category_attrib 
  Exceptions : Throws error if no attrib id can be found for the given value. 
  Status     : Stable
=cut

sub get_confidence_attrib {
  my $confidence_category = shift;
  $confidence_category = lc $confidence_category;
  $confidence_category =~ s/^\s+|\s+$//g;
  if ($confidence_category eq 'child if' || $confidence_category eq 'rd+if') {
    $confidence_category = 'both rd and if';
  }
  return $attrib_adaptor->get_attrib('confidence_category', $confidence_category);
}

=head2 get_allelic_requirement_attrib
  Arg [1]    : String $allelic_requirement - ',' or ';' separated list of
               allelic requirements from the import file
  Description: Get the allelic requirement attrib id(s) for the given
               allelic requirement value(s)
  Returntype : String $allelic_requirement_attrib 
  Exceptions : Throws error if no attrib id can be found for the given value. 
  Status     : Stable
=cut

sub get_allelic_requirement_attrib {
  my $allelic_requirement = shift;
  my @values = ();
  foreach my $value (split/;|,/, $allelic_requirement) {
    my $ar = lc $value;
    $ar =~ s/^\s+|\s+$|\s//g;
    push @values, $ar;
  }
  return $attrib_adaptor->get_attrib('allelic_requirement', join(',', @values));
}

=head2 get_mutation_consequence_attrib
  Arg [1]    : String $mutation_consequence - mutation consequence from the
               import file
  Description: Get the mutation consequence attrib if for the given
               mutation consequence value.
  Returntype : 
  Exceptions : Throws error if no attrib id can be found for the given value. 
  Status     : Stable
=cut

sub get_mutation_consequence_attrib {
  my $mutation_consequence = shift;
  $mutation_consequence = lc $mutation_consequence;
  $mutation_consequence =~ s/^\s+|\s+$//g;

  # Sometimes the provided mutational consequence is not
  # correct and we need to map it to the correct one first
  if ($supported_mc_values->{$mutational_consequence}) {
    return $attrib_adaptor->get_attrib('mutation_consequence', $supported_mc_values->{$mutational_consequence}); 
  } else {
    return  $attrib_adaptor->get_attrib('mutation_consequence', $mutation_consequence);
  }
}

=head2 add_publications
  Arg [1]    : GenomicFeatureDisease $gfd
  Arg [2]    : String $pmids - ';' or ',' separated list of PMID ids from the import file 
  Description: Add publications to the GenomicFeatureDisease entry.
  Returntype : None
  Exceptions : None
  Status     : Stable
=cut

sub add_publications {
  my $gfd = shift;
  my $pmids = shift;
  return if (!$pmids);
  my $gfd_id = $gfd->dbID;
  my @pubmed_ids = split(/;|,/, $pmids);
  foreach my $pmid (@pubmed_ids) {
    $pmid =~ s/^\s+|\s+$//g;
    $pmid =~ s/]//g;
    next unless($pmid);
    my $publication = $publication_adaptor->fetch_by_PMID($pmid);
    if (!$publication) {
      $publication = Bio::EnsEMBL::G2P::Publication->new(
        -pmid => $pmid,
      );
      $publication = $publication_adaptor->store($publication);
    }
    my $gfd_publication = $gfd_publication_adaptor->fetch_by_GFD_id_publication_id($gfd_id, $publication->dbID);
    if (!$gfd_publication) {
      $gfd_publication = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication->new(
        -genomic_feature_disease_id => $gfd_id,
        -publication_id => $publication->dbID,
        -adaptor => $gfd_publication_adaptor,
      );
      $gfd_publication_adaptor->store($gfd_publication);
    }
  }
}

=head2 add_phenotypes
  Arg [1]    : GenomicFeatureDisease $gfd
  Arg [2]    : String $phenotypes - ';' or ',' separated list of phenotype ids from the import file
  Arg [3]    : User $user
  Description: Add phenotypes to the GenomicFeatureDisease entry.
  Returntype : Warns about phenotype ids that cannot be found in the database.
  Exceptions : None
  Status     : Stable
=cut

sub add_phenotypes {
  my $gfd = shift;
  my $phenotypes = shift;
  my $user = shift;
  return if (!$phenotypes);
  my $gfd_id = $gfd->dbID;
  my $new_gfd_phenotypes = $gfd_phenotype_adaptor->fetch_all_by_GenomicFeatureDisease($gfd);
  my $new_gfd_phenotypes_lookup = {};
  foreach my $new_gfd_phenotype (@$new_gfd_phenotypes) {
    my $phenotype_id = $new_gfd_phenotype->get_Phenotype->dbID;
    $new_gfd_phenotypes_lookup->{"$gfd_id\t$phenotype_id"} = 1;
  }
  my @hpo_ids = split(/,|;/, $phenotypes || '');
  foreach my $hpo_id (@hpo_ids) {
    $hpo_id =~ s/^\s+|\s+$//g;
    my $phenotype = $phenotype_adaptor->fetch_by_stable_id($hpo_id);
    if (!$phenotype) {
      warn("Could not map given phenotype id ($hpo_id) to any phenotypes in the database: " . $gfd->get_GenomicFeature->gene_symbol . "\n");
    } else {
      my $phenotype_id = $phenotype->dbID;
      if (!$new_gfd_phenotypes_lookup->{"$gfd_id\t$phenotype_id"}) {
        my $new_gfd_phenotype = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePhenotype->new(
          -genomic_feature_disease_id => $gfd_id,
          -phenotype_id => $phenotype_id,
          -adaptor => $gfd_phenotype_adaptor,
        );
        $gfd_phenotype_adaptor->store($new_gfd_phenotype, $user);
      }
    }
  }
}

=head2 add_organ_specificity
  Arg [1]    : GenomicFeatureDisease $gfd
  Arg [2]    : String $organs - ';' or ',' separated list of organs from the import file
  Description: Add organs to the GenomicFeatureDisease entry.
  Returntype : Warns about organs that cannot be found in the database.
  Status     : Stable
=cut

sub add_organ_specificity {
  my $gfd = shift;
  my $organs = shift;
  return if (!$organs);
  my $gfd_id = $gfd->dbID;
  my $new_gfd_organs = $gfd_organ_adaptor->fetch_all_by_GenomicFeatureDisease($gfd);
  my $new_gfd_organs_lookup = {};
  foreach my $new_gfd_organ (@$new_gfd_organs) {
    my $organ_id = $new_gfd_organ->get_Organ->dbID;
    $new_gfd_organs_lookup->{"$gfd_id\t$organ_id"} = 1;
  }

  my @organ_names = split(/;|,/, $organs);
  foreach my $name (@organ_names) {
    $name =~ s/^\s+|\s+$//g;
    next unless($name);
    my $organ = $organ_adaptor->fetch_by_name($name);
    if (!$organ) {
      warn("Could not match given organ ($name) to any organ in the database:  " . $gfd->get_GenomicFeature->gene_symbol . "\n");
    } else {
      my $organ_id = $organ->dbID;
      if (!$new_gfd_organs_lookup->{"$gfd_id\t$organ_id"}) {
        my $new_gfd_organ =  Bio::EnsEMBL::G2P::GenomicFeatureDiseaseOrgan->new(
          -organ_id => $organ_id,
          -genomic_feature_disease_id => $gfd_id,
          -adaptor => $gfd_organ_adaptor, 
        );
        $gfd_organ_adaptor->store($new_gfd_organ);
        $new_gfd_organs_lookup->{"$gfd_id\t$organ_id"} = 1;
      }
    }
  }
}

=head2 add_comments
  Arg [1]    : GenomicFeatureDisease $gfd
  Arg [2]    : String $comments - Comments from the import file
  Arg [3]    : User $user
  Description: Add comments to the GenomicFeatureDisease entry.
  Returntype : None 
  Exceptions : None
  Status     : Stable
=cut

sub add_comment {
  my $gfd = shift;
  my $comments = shift;
  my $user = shift;
  return if (!$comments);
  $comments =~ s/^\s+|\s+$//g;
  my @existing_comments = @{$gfd_comment_adaptor->fetch_all_by_GenomicFeatureDisease($gfd)}; 
  if (! grep { $comments eq $_->comment_text} @existing_comments) {
    my $gfd_id = $gfd->dbID;
    my $gfd_comment = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseComment->new(
      -comment_text => $comments,
      -genomic_feature_disease_id => $gfd_id,
      -adaptor => $gfd_comment_adaptor,
    );
    $gfd_comment_adaptor->store($gfd_comment, $user);
  }
}

