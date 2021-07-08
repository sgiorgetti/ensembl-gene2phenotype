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
  'dryrun',
) or die "Error: Failed to parse command line arguments\n";

pod2usage(1) if ($config->{'help'} || !$args);

foreach my $param (qw/registry_file email import_file/) {
  die ("Argument --$param is required.") unless (defined($config->{$param}));
}

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);

my $species = 'human';
my $attrib_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'Attribute');
my $gf_adaptor     = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeature');
my $gfd_adaptor    = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDisease');
my $user_adaptor   = $registry->get_adaptor($species, 'gene2phenotype', 'User');

my $email = $config->{email};
my $user = $user_adaptor->fetch_by_email($email);
die "Couldn't fetch user for email $email" if (!defined $user);

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
  my $gfd_id = $data{'gfd_id'};
  my $allelic_requirement = $data{'allelic requirement'};
  my $mutation_consequence = $data{'mutation consequence'};

  my $gf = get_genomic_feature($gene_symbol);
  if (!$gf) {
    die "ERROR: No genomic feature for $gene_symbol\n";
  }

  my $allelic_requirement_attrib;
  my $mutation_consequence_attrib; 

  eval { $allelic_requirement_attrib = get_allelic_requirement_attrib($allelic_requirement) };
  if ($@) {
    die "There was a problem retrieving the allelic requirement attrib for entry value $allelic_requirement $@";
  }

  eval { $mutation_consequence_attrib = get_mutation_consequence_attrib($mutation_consequence) };
  if ($@) {
    die "There was a problem retrieving the mutation consequence attrib for entry value $mutation_consequence $@";
  }

  # We want to update the allelic requirement and/or the mutation consequence of an exisiting GFD
  # Check that there are no entries that already have the same gene symbol, allelic requirement and mutation consequence
  

  my $gfds = $gfd_adaptor->fetch_all_by_GenomicFeature_constraints(
    $gf,
    {
      'allelic_requirement_attrib' => $allelic_requirement_attrib,
      'mutation_consequence_attrib' => $mutation_consequence_attrib,
    }
  );

  if (scalar @$gfds > 0) {
    print STDERR "Entries with the same gene symbol, allelic requirement and mutation consequence already exist:\n";
    foreach my $gfd (@$gfds) {
      my $gfd_panels = join(', ', @{$gfd->panels});
      print STDERR "> ", join(', ', $gfd->get_GenomicFeature->gene_symbol, $gfd->get_Disease->name, $gfd->allelic_requirement, $gfd->mutation_consequence, $gfd_panels), "\n";
    }
    die;
  } else {
    # Update exisiting GFD
    if (!$config->{dryrun}) {
      my $gfd = $gfd_adaptor->fetch_by_dbID($gfd_id);
      if (!$gfd) {
        die "ERROR: Could not fetch GenomicFeatureDisease for gfd_id: $gfd_id\n";
      }
      my $has_changed = 0;
      if ($gfd->allelic_requirement_attrib ne $allelic_requirement_attrib) {
        $has_changed = 1;
        $gfd->allelic_requirement_attrib($allelic_requirement_attrib);
      }
      if ($gfd->mutation_consequence_attrib ne $mutation_consequence_attrib) {
        $has_changed = 1;
        $gfd->mutation_consequence_attrib($mutation_consequence_attrib);
      }
      if ($has_changed) {
        $gfd_adaptor->update($gfd, $user);
      }
    }
  }
}


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

sub get_mutation_consequence_attrib {
  my $mutation_consequence = shift;
  $mutation_consequence = lc $mutation_consequence;
  $mutation_consequence =~ s/^\s+|\s+$//g;
  return  $attrib_adaptor->get_attrib('mutation_consequence', $mutation_consequence);
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


