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
  'email=s',
) or die "Error: Failed to parse command line arguments\n";
die ('A registry_file file is required (--registry_file)') unless (defined($config->{registry_file}));

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);

my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');
my $user = $user_adaptor->fetch_by_email($config->{email});

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;
my $gfa = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeature');
my $gfda = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');
my $gene_adaptor = $registry->get_adaptor('human', 'core', 'gene');

my $disease_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'disease');

my $disease_name = 'PUF60 syndrome';

my $disease = $disease_adaptor->fetch_by_name($disease_name);


my $gfds = $gfda->fetch_all_by_Disease($disease);

print scalar @$gfds, "\n";

foreach my $gfd (@$gfds) {
  my $disease_name = $gfd->get_Disease->name;
  my $gene_symbol = $gfd->get_GenomicFeature->gene_symbol;
  $disease_name =~ s/PUF60/$gene_symbol/;  

  my $new_disease = $disease_adaptor->fetch_by_name($disease_name); 
  if (!$new_disease) {
    $new_disease =  Bio::EnsEMBL::G2P::Disease->new(
      -name => $disease_name,
      -adaptor => $disease_adaptor,
    );
    $new_disease = $disease_adaptor->store($new_disease);
  }

  $gfd->disease_id($new_disease->dbID);

  $gfd = $gfda->update($gfd, $user);

  print $gfd->dbID, "\n";

}



