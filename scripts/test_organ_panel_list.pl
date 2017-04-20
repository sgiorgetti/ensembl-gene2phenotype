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
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle; 
my $organ_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'organ');
my $organs = $organ_adaptor->fetch_all;
print scalar @$organs, "\n";
$organs = $organ_adaptor->fetch_all_by_panel_id(3);
foreach my $organ (@$organs) {
  print STDERR $organ->name, ' ', $organ->panel_id, "\n";
}
