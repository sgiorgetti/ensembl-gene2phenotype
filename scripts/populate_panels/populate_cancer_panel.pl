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
my $pa =  $registry->get_adaptor('human', 'gene2phenotype', 'Publication');

my $attrib_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'Attribute');
my $ua =  $registry->get_adaptor('human', 'gene2phenotype', 'User');
my $email = $config->{email};
my $user = $ua->fetch_by_email($email);

my $g2p_panel = 'Cancer';
my $panel_attrib_id = $attrib_adaptor->attrib_id_for_value($g2p_panel);

my $confidence_values = $attrib_adaptor->get_attribs_by_type_value('DDD_Category');
my $ar_values = $attrib_adaptor->get_attribs_by_type_value('allelic_requirement'); 
my $mc_values = $attrib_adaptor->get_attribs_by_type_value('mutation_consequence'); 

my $csv = Text::CSV->new({
  binary => 1, 
});

sub xlsx2txt {
  my $fh = FileHandle->new('.txt', 'w');
  my $book  = ReadData('.xlsx');
  my $sheet = $book->[1];      
  my @rows = Spreadsheet::Read::rows($sheet);
  foreach my $row (@rows) {
    my ($omim_disease, $disease_name, $omim_gene, $gene, $ar, $disease_confidence, $mc, $MTcomments, $pubmed) = @$row;
    next if ($omim_disease =~ /^OMIM/);
    my $gf = $gfa->fetch_by_gene_symbol($gene);

    my @substrings = split(/,\s\d+/, $disease_name);
    if (scalar @substrings > 1) {
      my $i=rindex($disease_name, ",");
      my $a=substr($disease_name, 0, $i);
      my $b=substr($disease_name, $i+1);
      $disease_name = $a;
    }

    $disease_name =~ s/{|}//g;
    $disease_name = uc $disease_name;

    my $disease = $da->fetch_by_name($disease_name);
    if (!$disease) {
      print $disease_name, "\n";
      $disease = Bio::EnsEMBL::G2P::Disease->new(
        -name => $disease_name,
        -adaptor => $da,
      ); 
      $da->store($disease);
    }

    $disease_confidence = lc $disease_confidence;
    my $disease_confidence_attrib = $confidence_values->{$disease_confidence};
    if (!$disease_confidence_attrib) {
      print $gene, ' ', $disease_confidence, "\n";
    }
    $ar = lc $ar;
    my $ar_attrib = $ar_values->{$ar} || undef;
    $mc =~ s/-/ /g;
    $mc = lc $mc;
    my $mc_attrib = $mc_values->{$mc} || undef;

    my $gfd = $gfda->fetch_by_GenomicFeature_Disease_panel_id($gf, $disease, $panel_attrib_id);

    if (!$gfd) {
      print "$disease_name $gene\n";
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
      print "$GFD_id $ar_attrib $mc_attrib\n";
      my $new_GFD_action = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseAction->new(
        -genomic_feature_disease_id => $GFD_id,
        -allelic_requirement_attrib => $ar_attrib,
        -mutation_consequence_attrib => $mc_attrib,
        -user_id => undef,
      );
      $new_GFD_action = $gfdaa->store($new_GFD_action, $user);
    }
    my @pubmed_ids = ();
    if ($pubmed) {
      my @ids = split(/,|;/, $pubmed);
      foreach my $id (@ids) {
        $id =~ s/^\s+|\s+$//g;
        if ($id =~ /^\d+$/) {
          push @pubmed_ids, $id; 
        }
      }
    }
    print $fh join("\t", $disease_name, $gene, $disease_confidence, $ar, $mc, join(',', @pubmed_ids)), "\n";
  }

  $fh->close();
}
my $file = $config->{import_file};
my $fh = FileHandle->new($file, 'r');
while (<$fh>) {
  chomp;
  my ($disease_name, $gene, $disease_confidence, $ar, $mc, $pubmed) = split/\t/;
  my $gf = $gfa->fetch_by_gene_symbol($gene);

  my @substrings = split(/,\s\d+/, $disease_name);
  if (scalar @substrings > 1) {
    my $i=rindex($disease_name, ",");
    my $a=substr($disease_name, 0, $i);
    my $b=substr($disease_name, $i+1);
    $disease_name = $a;
  }

  $disease_name =~ s/{|}//g;
  $disease_name = uc $disease_name;

  my $disease = $da->fetch_by_name($disease_name);
  if (!$disease) {
    print $disease_name, "\n";
    $disease = Bio::EnsEMBL::G2P::Disease->new(
      -name => $disease_name,
      -adaptor => $da,
    ); 
    $da->store($disease);
  }

  $disease_confidence = lc $disease_confidence;
  my $disease_confidence_attrib = $confidence_values->{$disease_confidence};
  $ar = lc $ar;
  my $ar_attrib = $ar_values->{$ar} || undef;
  $mc =~ s/-/ /g;
  $mc = lc $mc;
  my $mc_attrib = $mc_values->{$mc} || undef;

  my $gfd = $gfda->fetch_by_GenomicFeature_Disease_panel_id($gf, $disease, $panel_attrib_id);

  if (!$gfd) {
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
    my $allelic_requirement_attrib = $GFD_action->allelic_requirement_attrib;
    my $mutation_consequence_attrib = $GFD_action->mutation_consequence_attrib;
    $GFD_actions_lookup->{"$GFD_id\t$allelic_requirement_attrib\t$mutation_consequence_attrib"} = 1;
  }
  if (!$GFD_actions_lookup->{"$GFD_id\t$ar_attrib\t$mc_attrib"}) {
    my $new_GFD_action = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseAction->new(
      -genomic_feature_disease_id => $GFD_id,
      -allelic_requirement_attrib => $ar_attrib,
      -mutation_consequence_attrib => $mc_attrib,
      -user_id => undef,
    );
    $new_GFD_action = $gfdaa->store($new_GFD_action, $user);
  }

  if ($pubmed) {
    my @pubmed_ids = split(',', $pubmed);
    foreach my $pmid (@pubmed_ids) {
      my $publication = $pa->fetch_by_PMID($pmid);
      if (!$publication) {
        $publication = Bio::EnsEMBL::G2P::Publication->new(
          -pmid => $pmid,
        );
        $publication = $pa->store($publication);
      }
      my $GFDPublication = $gfdpa->fetch_by_GFD_id_publication_id($GFD_id, $publication->dbID);
      if (!$GFDPublication) {
        $GFDPublication = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication->new(
          -genomic_feature_disease_id => $GFD_id,
          -publication_id => $publication->dbID,
          -adaptor => $gfdpa,
        );
        $gfdpa->store($GFDPublication);
      }
    }
  }
}

$fh->close;


