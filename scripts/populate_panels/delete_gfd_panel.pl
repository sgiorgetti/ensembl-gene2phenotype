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
my $gfd_adaptor       = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDisease');
my $gfd_panel_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDiseasePanel');
my $user_adaptor      = $registry->get_adaptor($species, 'gene2phenotype', 'User');

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
  if ($row->[0] =~ /^gfd_id/) {
    @header = @$row;
    next;
  }
  my %data = map {$header[$_] => $row->[$_]} (0..$#header);

  my $gfd_id = $data{'gfd_id'};
  my $panel = $data{'panel'};

  my $gfd = $gfd_adaptor->fetch_by_dbID($gfd_id);
  if (!$gfd) {
    die "ERROR: Could not fetch GenomicFeatureDisease for gfd_id: $gfd_id\n";
  }

  my $gfd_panel = $gfd_panel_adaptor->fetch_by_GenomicFeatureDisease_panel($gfd, $panel);
  if (!$gfd_panel) {
    die "ERROR: Could not fetch GenomicFeatureDiseasePanel for gfd and panel: $panel\n";
  }
  if (!$config->{dryrun}) {
    $gfd_panel_adaptor->delete($gfd_panel, $user);
  }

}

