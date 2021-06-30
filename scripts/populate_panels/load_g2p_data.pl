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

load_g2p_data.pl 

=head1 DESCRIPTION

Imports new entries and annotations from a spreadsheet into the gene2phenotype database

=head1 SYNOPSIS

load_g2p_data.pl [arguments]

=head1 OPTIONS

=over 4

=item B<--help>

Displays this documentation

=item B<--gvf_file FILE>

GVF file which will be converted into a VCF file

=item B<--vcf_file FILE>

New VCF file
=item B<--species >
Species for which to genereate VCF file
=item B<--registry FILE>
Registry file which provides database connections
to core and variation databases from which the GVF
file was dumped. Database connections are
required for populating meta information in the VCF
file.
=item B<--fasta_file FILE>
Provide fasta file for sequence look ups which
otherwise would be achieved by database queries
which are slower. It is recommended to provide
a fasta file for human file conversions.
=item B<--ancestral_allele|aa>
Parse ancestral allele from GVF file and
store in new VCF file
=item B<--ancestral_allele_file FILE>
Provide the ancestral genome FASTA file for looking up
ancestral alleles. This is required for indels where
the allele string or position of the reference have changed
after formatting alleles to match the VCF format
=item B<--global_maf>
Parse minor allele, minor allele frequency and minor allele count
from GVF file and store in new VCF file
=item B<--evidence>
Parse evidence attributes (Multiple observations, Frequency, Cited,
Phenotype or Disease, 1000 Genomes, ESP, ExAC, gnomAD, TOPMed) from GVF file and store in new VCF file
=item B<--clinical_significance>
Parse clinical significance attributes from GVF file and
sotre in VCF file. Available attributes are described here:
https://www.ensembl.org/info/genome/variation/phenotype/phenotype_annotation.html#clin_significance
=item B<--structural_variations|svs>
Parse structural variants from GVF and store in VCF
=item B<--incl_consequences>
Parse variant consequences from GVF and store in VCF
=item B<--protein_coding_details>
Parse protein consequences from GVF and store in VCF
=item B<--sift>
Parse SIFT annotations from GVF and store in VCF
=item B<--polyphen>
Parse PolyPhen annotations from GVF and store in VCF
=item B<--individual STRING>
Individual name for which genotypes are stored in the GVF file.
The name will be stored in the VCF header line.
=back
=head1 CONTACT
  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.
  Questions may also be sent to the Ensembl help desk at
  <https://www.ensembl.org/Help/Contact>.
=cut

use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use DBI;
use FileHandle;
use Getopt::Long;
use Pod::Usage qw(pod2usage);
use Spreadsheet::Read;
use Text::CSV;

my $args = scalar @ARGV;
my $config = {};
GetOptions(
  $config,
  'help|h',
  'registry_file=s',
  'email=s',
  'import_file=s',
  'panel=s',
  'report_file=s',
) or die "Error: Failed to parse command line arguments\n";

pod2usage(1) if ($config->{'help'} || !$args);

foreach my $param (qw/registry_file email import_file panel report_file/) {
  die ("Argument --$param is required.") unless (defined($config->{$param}));
}

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);

my $species = 'human';
my $gf_adaptor                  = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeature');
my $disease_adaptor             = $registry->get_adaptor($species, 'gene2phenotype', 'Disease');
my $gfd_adaptor                 = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDisease');
my $gfd_panel_adaptor           = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseasePanel');
my $gfd_disease_synonym_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GFDDiseaseSynonym');
my $gfd_publication_adaptor     = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseasePublication');
my $gfd_organ_adaptor           = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseaseOrgan');
my $gfd_phenotype_adaptor       = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseasePhenotype');
my $publication_adaptor         = $registry->get_adaptor($species, 'gene2phenotype', 'Publication');
my $organ_adaptor               = $registry->get_adaptor($species, 'gene2phenotype', 'Organ');
my $phenotype_adaptor           = $registry->get_adaptor($species, 'gene2phenotype', 'Phenotype');
my $attrib_adaptor              = $registry->get_adaptor($species, 'gene2phenotype', 'Attribute');
my $user_adaptor                = $registry->get_adaptor($species, 'gene2phenotype', 'User');
my $gfd_comment_adaptor         = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseaseComment');

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

my $report_file = $config->{report_file};

my $import_stats = {};
my $fh_report = FileHandle->new($report_file, 'w');

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
    my $gfd = create_gfd($gf, $disease, $allelic_requirement_attrib, $mutation_consequence_attrib);
    add_gfd_to_panel($gfd, $g2p_panel, $confidence_attrib);
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
        add_gfd_to_panel($gfd, $g2p_panel, $confidence_attrib);
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
      my $gfd = create_gfd($gf, $disease, $allelic_requirement_attrib, $mutation_consequence_attrib);
      add_gfd_to_panel($gfd, $g2p_panel, $confidence_attrib);
      add_annotations($gfd, %data);
    }
  }
}

print $fh_report "Created " . $import_stats->{new_gfd} . " new GFDs.\n" if ($import_stats->{new_gfd});
print $fh_report "Added " . $import_stats->{add_to_panel}->{$g2p_panel} . " GFDs to the $g2p_panel panel.\n" if ($import_stats->{add_to_panel}->{$g2p_panel});

$fh_report->close();

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

  my $other_disease_names = $data{'other disease names'};
  my $phenotypes = $data{'phenotypes'};
  my $organs = $data{'organ specificity list'};
  my $pmids = $data{'pmids'};
  my $comments = $data{'comments'};

  my $count = add_other_disease_names($gfd, $other_disease_names);
  print $fh_report "    Added $count other disease names\n" if ($count > 0);

  $count = add_publications($gfd, $pmids); 
  print $fh_report "    Added $count publications\n" if ($count > 0);

  $count = add_phenotypes($gfd, $phenotypes, $user);
  print $fh_report "    Added $count phenotypes\n" if ($count > 0);

  $count = add_organ_specificity($gfd, $organs);
  print $fh_report "    Added $count organs\n" if ($count > 0);
  
  $count = add_comments($gfd, $comments, $user);
  print $fh_report "    Added $count comments\n" if ($count > 0);

}

=head2 create_gfd
  Arg [1]    : GenomicFeature
  Arg [2]    : Disease
  Arg [3]    : Integer $allelic_requirement_attrib - Can be a single attrib id or comma separated list of attrib ids.
  Arg [4]    : Integer $mutation_consequence_attrib - Single attrib id
  Description: Create a new GenomicFeatureDisease entry.
  Returntype : 
  Exceptions : None
  Status     : Stable
=cut

sub create_gfd {
  my ($gf, $disease, $allelic_requirement_attrib, $mutation_consequence_attrib) = @_;
  my $gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
      -genomic_feature_id => $gf->dbID,
      -disease_id => $disease->dbID,
      -allelic_requirement_attrib => $allelic_requirement_attrib,
      -mutation_consequence_attrib => $mutation_consequence_attrib,
      -adaptor => $gfd_adaptor,
    );
  $gfd = $gfd_adaptor->store($gfd, $user);

  my $allelic_requirement = $gfd->allelic_requirement;
  my $mutation_consequence = $gfd->mutation_consequence;

  $import_stats->{new_gfd}++;
  print $fh_report "Create new GFD: ", $gf->gene_symbol, ", ", $disease->name, ", $allelic_requirement, $mutation_consequence\n"; 

  return $gfd;
}

=head2 add_gfd_to_panel
  Arg [1]    : GenomicFeatureDisease database
  Arg [2]    : String $g2p_panel - Add GFD to this panel
  Arg [3]    : Integer $confidence_attrib - Single attrib id
  Description: Create a new GenomicFeatureDiseasePanel entry.
  Returntype : 
  Exceptions : None
  Status     : Stable
=cut

sub add_gfd_to_panel {
  my ($gfd, $g2p_panel, $confidence_attrib) = @_;
  my $gfd_panel =  Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel->new(
    -genomic_feature_disease_id => $gfd->dbID,
    -panel => $g2p_panel,
    -confidence_category_attrib => $confidence_attrib,
    -adaptor => $gfd_panel_adaptor,
  );
  $gfd_panel = $gfd_panel_adaptor->store($gfd_panel, $user); 

  my $gene_symbol = $gfd->get_GenomicFeature->gene_symbol;
  my $disease_name = $gfd->get_Disease->name;
  my $allelic_requirement = $gfd->allelic_requirement;
  my $mutation_consequence = $gfd->mutation_consequence;
  my $confidence_category = $gfd_panel->confidence_category;
 
  $import_stats->{add_to_panel}->{$g2p_panel}++;
 
  print $fh_report "Add GFD: $gene_symbol, $disease_name, $allelic_requirement, $mutation_consequence to $g2p_panel with confidence $confidence_category\n"; 
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
  print STDERR "get_confidence_attrib $confidence_category\n";
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
  if ($supported_mc_values->{$mutation_consequence}) {
    return $attrib_adaptor->get_attrib('mutation_consequence', $supported_mc_values->{$mutation_consequence}); 
  } else {
    return  $attrib_adaptor->get_attrib('mutation_consequence', $mutation_consequence);
  }
}

=head2 add_other_disease_names
  Arg [1]    : GenomicFeatureDisease $gfd
  Arg [2]    : String $disease_names - ';' or ',' separated list of other disease names from the import file 
  Description: Add other disease names to the GenomicFeatureDisease entry.
  Returntype : None
  Exceptions : None
  Status     : Stable
=cut

sub add_other_disease_names {
  my $gfd = shift;
  my $disease_names = shift;
  return 0 if (!$disease_names);
  my $gfd_id = $gfd->dbID;
  my $count = 0;
  foreach my $disease_name (split(/;/, $disease_names)) {
    $disease_name =~ s/^\s+|\s+$//g;
    my $disease = get_disease($disease_name);
    my $gfd_disease_synonym = $gfd_disease_synonym_adaptor->fetch_by_GFD_id_disease_id($gfd_id, $disease->dbID);
    if (!$gfd_disease_synonym) {
      $gfd_disease_synonym = Bio::EnsEMBL::G2P::GFDDiseaseSynonym->new(
        -genomic_feature_disease_id => $gfd_id,
        -disease_id => $disease->dbID,
        -adaptor => $gfd_publication_adaptor,
      );
      $gfd_disease_synonym_adaptor->store($gfd_disease_synonym);
      $count++;
    }
  }
  return $count;
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
  return 0 if (!$pmids);
  my $gfd_id = $gfd->dbID;
  my @pubmed_ids = split(/;|,/, $pmids);
  my $count = 0;
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
      $count++;
    }
  }
  return $count;
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
  return 0 if (!$phenotypes);
  my $gfd_id = $gfd->dbID;
  my $count = 0;
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
        $count++;
      }
    }
  }
  return $count;
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
  return 0 if (!$organs);
  my $gfd_id = $gfd->dbID;
  my $new_gfd_organs = $gfd_organ_adaptor->fetch_all_by_GenomicFeatureDisease($gfd);
  my $new_gfd_organs_lookup = {};
  my $count = 0;
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
        $count++;
      }
    }
  }
  return $count;
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

sub add_comments {
  my $gfd = shift;
  my $comments = shift;
  my $user = shift;
  return 0 if (!$comments);
  $comments =~ s/^\s+|\s+$//g;
  my $count = 0;
  my @existing_comments = @{$gfd_comment_adaptor->fetch_all_by_GenomicFeatureDisease($gfd)}; 
  if (! grep { $comments eq $_->comment_text} @existing_comments) {
    my $gfd_id = $gfd->dbID;
    my $gfd_comment = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseComment->new(
      -comment_text => $comments,
      -genomic_feature_disease_id => $gfd_id,
      -adaptor => $gfd_comment_adaptor,
    );
    $gfd_comment_adaptor->store($gfd_comment, $user);
    $count++;
  }
  return $count;
}
