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
my $gfd_action_adaptor       = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseaseAction');
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

my $file = $config->{import_file};
die "Data file $file doesn't exist" if (!-e $file);
my $book  = ReadData($file);
my $sheet = $book->[1];
my @rows = Spreadsheet::Read::rows($sheet);
foreach my $row (@rows) {
   
  my ($gene_symbol, $gene_mim, $disease_name, $disease_mim, $DDD_category, $allelic_requirement, $mutation_consequence, $phenotypes,  $organs,  $pmids,  $panel,  $prev_symbols, $hgnc_id, $comments) = @$row;
  next if ($gene_symbol =~ /^gene/);

  my $gf = get_genomic_feature($gene_symbol, $prev_symbols);
  my $disease = get_disease($disease_name, $disease_mim);

  my $disease_confidence_attrib = get_disease_confidence_attrib($DDD_category);

  my $allelic_requirement_attrib = get_allelic_requirement_attrib($allelic_requirement);

  my $mutation_consequence_attrib = get_mutation_consequence_attrib($mutation_consequence);

  my $gfd = $gfd_adaptor->fetch_by_GenomicFeature_Disease_panel_id($gf, $disease, $panel_attrib_id);

  if (!$gfd) {
    print "Add new GFD $gene_symbol $disease_name ", $disease->dbID, "\n";
    $gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
      -genomic_feature_id => $gf->dbID,
      -disease_id => $disease->dbID,
      -panel_attrib => $panel_attrib_id,
      -confidence_category_attrib => $disease_confidence_attrib,
      -adaptor => $gfd_adaptor,
    );
    $gfd = $gfd_adaptor->store($gfd, $user);
  }

  add_genomic_feature_disease_action($gfd, $allelic_requirement_attrib, $mutation_consequence_attrib);

  add_publications($gfd, $pmids); 

  add_phenotypes($gfd, $phenotypes);

  add_organ_specificity($gfd, $organs);
  
  add_comments($gfd, $comments, $user);

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
  print STDERR "No genomic_feature for $gene_symbol \n";
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
  if ($disease_confidence eq 'child if') {
    $disease_confidence = 'both DD and IF';
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
  if (!$mc_attrib && $mc) {
    die "no mutation consequence attrib for $mutation_consequence\n";
  }
  return $mc_attrib;
}

sub add_genomic_feature_disease_action {
  my $gfd = shift;
  my $allelic_requirement_attrib = shift;
  my $mutation_consequence_attrib = shift;

  my $gfd_id = $gfd->dbID;
  my $gfd_actions = $gfd_action_adaptor->fetch_all_by_GenomicFeatureDisease($gfd);
  my $gfd_actions_lookup = {};
  foreach my $gfd_action (@$gfd_actions) {
    my $allelic_requirement_attrib = $gfd_action->allelic_requirement_attrib || '';
    my $mutation_consequence_attrib = $gfd_action->mutation_consequence_attrib || '';
    $gfd_actions_lookup->{"$gfd_id\t$allelic_requirement_attrib\t$mutation_consequence_attrib"} = 1;
  }

  if (!$gfd_actions_lookup->{"$gfd_id\t$allelic_requirement_attrib\t$mutation_consequence_attrib"}) {
    print "add_genomic_feature_disease_action $gfd_id $allelic_requirement_attrib $mutation_consequence_attrib\n";
    my $new_gfd_action = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseAction->new(
      -genomic_feature_disease_id => $gfd_id,
      -allelic_requirement_attrib => $allelic_requirement_attrib,
      -mutation_consequence_attrib => $mutation_consequence_attrib,
      -user_id => undef,
    );
    $new_gfd_action = $gfd_action_adaptor->store($new_gfd_action, $user);
  }
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
      print "add_publications $gfd_id $pmid\n";
      $gfd_publication_adaptor->store($gfd_publication);
    }
  }
}

sub add_phenotypes {
  my $gfd = shift;
  my $phenotypes = shift;
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
        $gfd_phenotype_adaptor->store($new_gfd_phenotype);
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

  my @organ_names = split(';', $organs);
  foreach my $name (@organ_names) {
    $name =~ s/^\s+|\s+$//g;
    next unless($name);
    my $organ = $organ_adaptor->fetch_by_name($name);
    if (!$organ) {
      print STDERR "No Organ for $name gfd_id " . $gfd->get_GenomicFeature->gene_symbol ."\n";
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
  my $gfd_id = $gfd->dbID;
  my $gfd_comment = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseComment->new(
    -comment_text => $comments,
    -genomic_feature_disease_id => $gfd_id,
    -adaptor => $gfd_comment_adaptor,
  );
  print "add GFD comment $gfd_id $comments\n";
  $gfd_comment_adaptor->store($gfd_comment, $user);
}


