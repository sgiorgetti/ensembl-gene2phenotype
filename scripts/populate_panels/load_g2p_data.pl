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
my $g2p_panel = $config->{panel};
my $panel_attrib_id = $attrib_adaptor->attrib_id_for_value($g2p_panel);
die "Couldn't fetch panel_attrib_id for panel $g2p_panel" if (!defined $g2p_panel);

my $confidence_values = $attrib_adaptor->get_attribs_by_type_value('confidence_category');
%{$confidence_values} = map { lc $_ => $confidence_values->{$_} } keys %{$confidence_values};
my $ar_values = $attrib_adaptor->get_attribs_by_type_value('allelic_requirement'); 
my $mc_values = $attrib_adaptor->get_attribs_by_type_value('mutation_consequence'); 

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
  my $phenotypes = $data{'phenotypes'};
  my $organs = $data{'organ specificity list'};
  my $pmids = $data{'pmids'};
  my $panel = $data{'panel'};
  my $prev_symbols = $data{'prev symbols'};
  my $hgnc_id = $data{'hgnc id'};
  my $comments = $data{'comments'};
  my $restricted_mutation_set = $data{'restricted mutation set'};

  if (!$panel) {
    warn "No panel for gene $gene_symbol\n";
    next;
  }
  next if (!add_to_panel($panel));  

  my $gf = get_genomic_feature($gene_symbol, $prev_symbols);
  if (!$gf) {
    die "No genomic feature for $gene_symbol\n";
  }

  my $disease_confidence_attrib = get_disease_confidence_attrib($DDD_category);

  my $allelic_requirement_attrib = get_allelic_requirement_attrib($allelic_requirement);
  if (!$allelic_requirement_attrib) {
    die "No allelic requirement for $gene_symbol\n";
  }

  my $mutation_consequence_attrib = get_mutation_consequence_attrib($mutation_consequence);
  if (!$mutation_consequence_attrib) {
    die "No mutation consequence for $gene_symbol\n";
  }

  if (!$disease_name) {
    die "No disease name for $gene_symbol, $allelic_requirement, $mutation_consequence\n";
  }

  my $disease = get_disease($disease_name, $disease_mim);


  # Try to get existing entries with same gene symbol, allelic requirement and mutation consequence

  my $gfds = $gfd_adaptor->fetch_all_by_GenomicFeature_panel($gf, $panel);

  my @gfds_matched_ar_and_mc = grep {$_->allelic_requirement_attrib eq $allelic_requirement_attrib && $_->mutation_consequence_attrib eq $mutation_consequence_attrib} @{$gfds}; 

  if (scalar @gfds_matched_ar_and_mc > 0) {
    foreach my $gfd (@gfds_matched_ar_and_mc) {
      warn("Entry with same gene symbol, allelic requirement and mutation consequence exists: " . join(" ", $gfd->get_GenomicFeature->gene_symbol, $gfd->allelic_requirement, $gfd->mutation_consequence, $gfd->get_Disease->name) . "\n");
    }
    if ($restricted_mutation_set eq 'y') {
      warn("Create new entry with restricted mutation set for: " . join(" ", $gfd->get_GenomicFeature->gene_symbol, $gfd->allelic_requirement, $gfd->mutation_consequence, $gfd->get_Disease->name) . "\n");
    } else {
      next;
    }
  }

  # Try to get existing GFD from database by genomic_feature, allelic requirement, mutation consequence and disease name. fetch_all_by_GenomicFeature_Disease_panel also considers disease name synonyms.
  # In two steps:
  # 1) get all GFD by gene and disease  
  $gfds = $gfd_adaptor->fetch_all_by_GenomicFeature_Disease_panel($gf, $disease, $panel);
  # 2) then compare by allelic requirement and mutation consequence
  my ($gfd) = grep {$_->allelic_requirement_attrib eq $allelic_requirement_attrib && $_->mutation_consequence_attrib eq $mutation_consequence_attrib} @{$gfds}; 

  if ($gfd) {
    # only update confidence:
    # TODO is confidence value different and does it need to be updated:
    # If yes:
    $gfd->confidence_category_attrib($disease_confidence_attrib);
    $gfd_adaptor->update($gfd, $user);
  } else {
    # create new GFD
    $gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
      -genomic_feature_id => $gf->dbID,
      -disease_id => $disease->dbID,
      -panel_attrib => $panel_attrib_id,
      -confidence_category_attrib => $disease_confidence_attrib,
      -allelic_requirement_attrib => $allelic_requirement_attrib,
      -mutation_consequence_attrib => $mutation_consequence_attrib,
      -adaptor => $gfd_adaptor,
    );
    $gfd = $gfd_adaptor->store($gfd, $user);
  }

  add_publications($gfd, $pmids); 

  add_phenotypes($gfd, $phenotypes, $user);

  add_organ_specificity($gfd, $organs);
  
  add_comments($gfd, $comments, $user);

}

sub add_to_panel {
  my $panels = shift;
  my $add = 0;
  foreach my $panel (split/;|,/, $panels) {
    $panel =~ s/^\s+|\s+$//g;
    if ($panel eq $g2p_panel) {
      return 1;
    }
  } 
  return $add;
}

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

sub get_disease_confidence_attrib {
  my $DDD_category = shift;
  my $disease_confidence = lc $DDD_category;
  $disease_confidence =~ s/^\s+|\s+$//g;
  if ($disease_confidence eq 'child if' || $disease_confidence eq 'rd+if') {
    $disease_confidence = 'both rd and if';
  }
  my $disease_confidence_attrib = $confidence_values->{$disease_confidence};
  if (!$disease_confidence_attrib) {
    die "No disease confidence attrib for $disease_confidence \n";
  }
  return $disease_confidence_attrib;
}

sub get_allelic_requirement_attrib {
  my $allelic_requirement = shift;
  my $ar = lc $allelic_requirement;
  $ar =~ s/^\s+|\s+$//g;
  my $ar_attrib = $ar_values->{$ar} || undef;
  if (!$ar_attrib && $ar) {
    die "no allelic requirement attrib for $allelic_requirement\n";
  }
  return $ar_attrib;
}

sub get_mutation_consequence_attrib {
  my $mutation_consequence = shift;
  my $mc = lc $mutation_consequence;
  $mc =~ s/^\s+|\s+$//g;

  my $mc_attrib = $mc_values->{$mc} || undef;

  # try some variations
  if (!$mc_attrib) {
    $mc = $supported_mc_values->{$mc};  
    $mc_attrib = $mc_values->{$mc} || undef;
  }

  if (!$mc_attrib) {
    die "no mutation consequence attrib for $mutation_consequence\n";
  }
  return $mc_attrib;
}

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
      print STDERR 'No phenotype ', $hpo_id, "\n";
     } else {
      my $phenotype_id = $phenotype->dbID;
      if (!$new_gfd_phenotypes_lookup->{"$gfd_id\t$phenotype_id"}) {
        my $new_gfd_phenotype = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePhenotype->new(
          -genomic_feature_disease_id => $gfd_id,
          -phenotype_id => $phenotype_id,
          -adaptor => $gfd_phenotype_adaptor,
        );
        print "add_phenotypes $gfd_id $hpo_id\n";
        $gfd_phenotype_adaptor->store($new_gfd_phenotype, $user);
      }
    }
  }
}

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
      print STDERR "No organ for $name gfd_id " . $gfd->get_GenomicFeature->gene_symbol ."\n";
    } else {
      my $organ_id = $organ->dbID;
      if (!$new_gfd_organs_lookup->{"$gfd_id\t$organ_id"}) {
        my $new_gfd_organ =  Bio::EnsEMBL::G2P::GenomicFeatureDiseaseOrgan->new(
          -organ_id => $organ_id,
          -genomic_feature_disease_id => $gfd_id,
          -adaptor => $gfd_organ_adaptor, 
        );
        print "add_organ_specificity $gfd_id $organ_id\n";
        $gfd_organ_adaptor->store($new_gfd_organ);
        $new_gfd_organs_lookup->{"$gfd_id\t$organ_id"} = 1;
      }
    }
  }
}

sub add_comments {
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
    print "add GFD comment $gfd_id $comments\n";
    $gfd_comment_adaptor->store($gfd_comment, $user);
  }
}

