#!/software/bin/perl

use strict;
use warnings;

use Data::Dumper;
use DBI;
use FileHandle;
use Getopt::Long;
use HTTP::Tiny;
use JSON;
use Bio::EnsEMBL::Registry;

# perl update_publication.pl -registry_file registry

my $config = {};

GetOptions(
  $config,
  'registry_file=s',
  'working_dir=s',
) or die "Error: Failed to parse command line arguments\n";
die ('A registry_file file is required (--registry_file)') unless (defined($config->{registry_file}));

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;

my $gfa = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeature');
my $gfda = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');


my $gfds = $gfda->fetch_all_by_panel('DD');

print scalar @$gfds, "\n";

my $count_with_publications = 0;

my $disease_confidence = {};
my $ars = {};
my $mcs = {};

foreach my $gfd (@$gfds) {
  my $publications = $gfd->get_all_GFDPublications;
  if (scalar @$publications > 0) {
    $count_with_publications++;
    my $DDD_category = $gfd->DDD_category;
    $disease_confidence->{$DDD_category}++;

    my $gfdas = $gfd->get_all_GenomicFeatureDiseaseActions;
    foreach my $gfda (@$gfdas) {
      my $ar = $gfda->allelic_requirement;
      $ars->{$ar}++;
      my $mc = $gfda->mutation_consequence;
      $mcs->{$mc}++;
    }
  }
}

print $count_with_publications, "\n";

print STDERR "disease confidence\n";

foreach my $key (sort {$disease_confidence->{$b} <=> $disease_confidence->{$a}} keys %$disease_confidence) {
  print $key, ' ', $disease_confidence->{$key}, "\n";
}


print STDERR "\nallelic requirement\n";

foreach my $key (sort {$ars->{$b} <=> $ars->{$a}} keys %$ars) {
  print $key, ' ', $ars->{$key}, "\n";
}

print STDERR "\nmutation consequence\n";

foreach my $key (sort {$mcs->{$b} <=> $mcs->{$a}} keys %$mcs) {
  print $key, ' ', $mcs->{$key}, "\n";
}






