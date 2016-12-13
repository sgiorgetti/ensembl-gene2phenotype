#!/software/bin/perl

use strict;
use warnings;

use DBI;
use FileHandle;
use Getopt::Long;
use HTTP::Tiny;
use JSON;
use Bio::EnsEMBL::Registry;
use Encode qw(decode encode);

# perl update_publication.pl -registry_file registry

my $config = {};

#GetOptions(
#  $config,
#  'registry_file=s',
#) or die "Error: Failed to parse command line arguments\n";
#die ('A registry_file file is required (--registry_file)') unless (defined($config->{registry_file}));


#my $registry = G2P::Registry->new($config->{registry_file});

my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all('');

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle; 


my $gfda = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');

my $gfds = $gfda->fetch_all_by_panel_without_publications('Cancer');

print scalar @$gfds, "\n";

foreach my $gfd (@$gfds) {
  my $gene_symbol = $gfd->get_GenomicFeature->gene_symbol;
  my $disease_name = $gfd->get_Disease->name;
  print "$gene_symbol $disease_name\n";

}
