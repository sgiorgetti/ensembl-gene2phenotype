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

my $gfa = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeature');
my $da = $registry->get_adaptor('human', 'gene2phenotype', 'Disease');
my $gfda = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');
my $gfdaa = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseaseAction');
my $gfdpa =  $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseasePublication');
my $gfdoa =  $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseaseOrgan');

my $gfd_phenotype_a =  $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseasePhenotype');

my $pa =  $registry->get_adaptor('human', 'gene2phenotype', 'Publication');
my $oa =  $registry->get_adaptor('human', 'gene2phenotype', 'Organ');
my $phenotype_a =  $registry->get_adaptor('human', 'gene2phenotype', 'Phenotype');


my $attrib_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'Attribute');
my $ua =  $registry->get_adaptor('human', 'gene2phenotype', 'User');
my $email = $config->{email};
my $user = $ua->fetch_by_email($email);

my $g2p_panel = 'Skin';
my $panel_attrib_id = $attrib_adaptor->attrib_id_for_value($g2p_panel);

my $confidence_values = $attrib_adaptor->get_attribs_by_type_value('DDD_Category');
my $ar_values = $attrib_adaptor->get_attribs_by_type_value('allelic_requirement'); 
my $mc_values = $attrib_adaptor->get_attribs_by_type_value('mutation_consequence'); 

my $file = $config->{import_file};
my $book  = ReadData($file);
my $sheet = $book->[1];
my @rows = Spreadsheet::Read::rows($sheet);
foreach my $row (@rows) {
  my ($gene_symbol, $gene_mim, $disease_name, $disease_mim, $DDD_category, $allelic_requirement, $mutation_consequence, $phenotypes,  $organs,  $pmids,  $panel,  $prev_symbols, $hgnc_id) = @$row;
  next if ($gene_symbol =~ /^gene/);
  my $gf = $gfa->fetch_by_gene_symbol($gene_symbol);
  if (!$gf) {
    $gf = $gfa->fetch_by_synonym($gene_symbol);
    if (!$gf) {
      print "No genomic_feature for $gene_symbol \n";
      next;
    }
  }

  $disease_name =~ s/"//g;
  my $disease = $da->fetch_by_name($disease_name);
  if (!$disease) {
    print "Added new disease name $disease_name\n";
    $disease = Bio::EnsEMBL::G2P::Disease->new(
      -name => $disease_name,
      -adaptor => $da,
    ); 
    $da->store($disease);
  }

  my $disease_confidence = lc $DDD_category;
  my $disease_confidence_attrib = $confidence_values->{$disease_confidence};
  if (!$disease_confidence_attrib) {
    die "No disease confidence attrib for $disease_confidence \n";
  }
  my $ar = lc $allelic_requirement;

  if ($ar eq 'hemizygous (males); monoallelic (females)' || $ar eq 'monoallelic, bilallelic ansd mosaic reported') {
    warn "$ar\n";
    next;
  }

  $ar =~ s/^\s+|\s+$//g;
  if ($ar eq 'monoalellelic') {
    $ar = 'monoallelic';
  }
  my $ar_attrib = $ar_values->{$ar} || undef;
  if (!$ar_attrib && $ar) {
    die "no allelic requirement for $gene_symbol $allelic_requirement\n";
  }
#  my $mc =~ s/-/ /g;
  my $mc = lc $mutation_consequence;
  my $mc_attrib = $mc_values->{$mc} || undef;
  if (!$mc_attrib && $mc) {
    die "no mutation consquence for $gene_symbol $mutation_consequence\n";
  }
  
  my $gfd = $gfda->fetch_by_GenomicFeature_Disease_panel_id($gf, $disease, $panel_attrib_id);

  if (!$gfd) {
    print "Add new GFD $gene_symbol $disease_name ", $disease->dbID, "\n";
    $gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
      -genomic_feature_id => $gf->dbID,
      -disease_id => $disease->dbID,
      -panel_attrib => $panel_attrib_id,
      -DDD_category_attrib => $disease_confidence_attrib,
      -adaptor => $gfda,
    );
    $gfd = $gfda->store($gfd, $user);
  }

  my $GFD_id = $gfd->dbID;
  my $GFD_actions = $gfdaa->fetch_all_by_GenomicFeatureDisease($gfd);
  my $GFD_actions_lookup = {};
  foreach my $GFD_action (@$GFD_actions) {
    my $allelic_requirement_attrib = $GFD_action->allelic_requirement_attrib || '';
    my $mutation_consequence_attrib = $GFD_action->mutation_consequence_attrib || '';
    $GFD_actions_lookup->{"$GFD_id\t$allelic_requirement_attrib\t$mutation_consequence_attrib"} = 1;
  }

  my $lookup_ar = $ar_attrib || '';
  my $lookup_mc = $mc_attrib || '';

  if (!$GFD_actions_lookup->{"$GFD_id\t$lookup_ar\t$lookup_mc"}) {
    print "$GFD_id $lookup_ar $lookup_mc\n";
    my $new_GFD_action = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseAction->new(
      -genomic_feature_disease_id => $GFD_id,
      -allelic_requirement_attrib => $ar_attrib,
      -mutation_consequence_attrib => $mc_attrib,
      -user_id => undef,
    );
    $new_GFD_action = $gfdaa->store($new_GFD_action, $user);
  }

  if ($pmids) {
    my @pubmed_ids = split(/;|,/, $pmids);
    foreach my $pmid (@pubmed_ids) {
      $pmid =~ s/^\s+|\s+$//g;
      next unless($pmid);
      print "PMID $pmid\n";
      my $publication = $pa->fetch_by_PMID($pmid);
      if (!$publication) {
        $publication = Bio::EnsEMBL::G2P::Publication->new(
          -pmid => $pmid,
        );
        $publication = $pa->store($publication);
      }
      my $GFDPublication = $gfdpa->fetch_by_GFD_id_publication_id($GFD_id, $publication->dbID);
      if (!$GFDPublication) {
        print $publication->dbID, "\n";
        $GFDPublication = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication->new(
          -genomic_feature_disease_id => $GFD_id,
          -publication_id => $publication->dbID,
          -adaptor => $gfdpa,
        );
        $gfdpa->store($GFDPublication);
      }
    }
  }

  my $new_GFD_phenotypes = $gfd_phenotype_a->fetch_all_by_GenomicFeatureDisease($gfd);
  my $new_GFD_phenotypes_lookup = {};
  foreach my $new_GFD_phenotype (@$new_GFD_phenotypes) {
    my $phenotype_id = $new_GFD_phenotype->get_Phenotype->dbID;
    $new_GFD_phenotypes_lookup->{"$GFD_id\t$phenotype_id"} = 1;
  }

  my @hpo_ids = split(';', $phenotypes);
  foreach my $hpo_id (@hpo_ids) {
    $hpo_id =~ s/^\s+|\s+$//g;
    my $phenotype = $phenotype_a->fetch_by_stable_id($hpo_id);
    if (!$phenotype) {
      print $hpo_id, "\n";
     } else {
      my $phenotype_id = $phenotype->dbID;
      if (!$new_GFD_phenotypes_lookup->{"$GFD_id\t$phenotype_id"}) {
        my $new_GFDP = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePhenotype->new(
          -genomic_feature_disease_id => $GFD_id,
          -phenotype_id => $phenotype_id,
          -adaptor => $gfd_phenotype_a,
        );
        $gfd_phenotype_a->store($new_GFDP);
      }
    }
  }

  my $new_GFD_organs = $gfdoa->fetch_all_by_GenomicFeatureDisease($gfd);
  my $new_GFD_organs_lookup = {};
  foreach my $new_GFD_organ (@$new_GFD_organs) {
    my $organ_id = $new_GFD_organ->get_Organ->dbID;
    $new_GFD_organs_lookup->{"$GFD_id\t$organ_id"} = 1;
  }

  my $organ_mappings = {
    'hair' => 'Hair/Nails',
    'Cardiovasculature' => 'Heart/Cardiovasculature/Lymphatic',
    'Cardiovascular' => 'Heart/Cardiovasculature/Lymphatic',
    'Teeth and Dentitian' => 'Teeth & Dentitian',
    'teeth and dentitian' => 'Teeth & Dentitian',
    'Teeth/Dentition' => 'Teeth & Dentitian',
    'teeth' => 'Teeth & Dentitian',
    'Hair/Nail' => 'Hair/Nails',
    'Heart/Cardiovasculature' => 'Heart/Cardiovasculature/Lymphatic',
    'Heart/Cardiovascular/Lymphatic' => 'Heart/Cardiovasculature/Lymphatic',
    'Hair/nail' => 'Hair/Nails',
    'Hair' => 'Hair/Nails',
    'Kidney/renal tract' => 'Kidney Renal Tract',
    'Kidney/Renal tract' => 'Kidney Renal Tract',
    'Renal tract' => 'Kidney Renal Tract',
    'Metabolic/endocrine' => 'Endocrine/Metabolic', 
    'Respiratory' => 'Respiratory tract',
    'Heart' => 'Heart/Cardiovasculature/Lymphatic',
    'Heart/cardiovasculature' => 'Heart/Cardiovasculature/Lymphatic',
    'heart' => 'Heart/Cardiovasculature/Lymphatic',
    'Nails/hair' => 'Hair/Nails',
    'Ears' => 'Ear',
    'Eyes' => 'Eye',
    'Skeletal' => 'Skeleton',
    'Spinal cord/peripheral nerves/musculature' => 'Peripheral nerves',
    'Nails' => 'Hair/Nails',
    'Gasrtointestinal' => 'GI tract',
    'Gasttrointestinal' => 'GI tract',
    'Gastrointestinal' => 'GI tract',
    'Metobolic/endocrine' => 'Endocrine/Metabolic',
    'Central Nervous system' => 'Brain/Cognition', 
    'Immunological' => 'Bone Marrow/Immune',
    'Immune' => 'Bone Marrow/Immune',
    'Immune/bone marrow' => 'Bone Marrow/Immune',
    'Haematological' => 'Bone Marrow/Immune',
    'Genitourinary' => 'Genitalia',
    'Central Nervous System' => 'Brain/Cognition',
    'Musculoskeletal' => 'Skeleton',
    'Spinal cord/perihperal nerves' => 'Spinal cord/Peripheral nerves',
    'Spinal cord' => 'Spinal cord/Peripheral nerves',
    'Brain/congition' => 'Brain/Cognition',
    'Nose' => 'Face',
    'Mouth' => 'Face',
    'Lung' => 'Lungs',
  };

  my @organ_names = split(';', $organs);
  foreach my $name (@organ_names) {
    $name =~ s/^\s+|\s+$//g;
    next unless($name);
    if ($organ_mappings->{$name}) {
      $name = $organ_mappings->{$name};
    }
    if ($name =~ /teeth|Teeth|Dentitian/) {
      $name = 'Teeth & Dentitian';
    } elsif ($name =~ /Renal|renal/) {
      $name = 'Kidney Renal Tract';
    }
    my $organ = $oa->fetch_by_name($name);
    if (!$organ) {
      die "No Organ for $name\n";
    } else {
      my $organ_id = $organ->dbID;
      if (!$new_GFD_organs_lookup->{"$GFD_id\t$organ_id"}) {
        my $new_GFD_organ =  Bio::EnsEMBL::G2P::GenomicFeatureDiseaseOrgan->new(
          -organ_id => $organ_id,
          -genomic_feature_disease_id => $GFD_id,
          -adaptor => $gfdoa, 
        );
        $gfdoa->store($new_GFD_organ);
        $new_GFD_organs_lookup->{"$GFD_id\t$organ_id"} = 1;
      }
    }
  }
}
#$fh->close;





