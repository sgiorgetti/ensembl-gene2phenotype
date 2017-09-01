use strict;
use warnings;

use DBI;
use FileHandle;
use Getopt::Long;
use Bio::EnsEMBL::Registry;
my $config = {};

GetOptions(
  $config,
  'registry_file=s',
  'output_file=s',
) or die "Error: Failed to parse command line arguments\n";

my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all($config->{'registry_file'});

my $fh = FileHandle->new($config->{output_file}, 'w');

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle; 

my $sth = $dbh->prepare(q{
  SELECT disease_id, name  FROM disease;
}, {mysql_use_result => 1});
$sth->execute() or die $dbh->errstr;
my ($disease_id, $name, $new_name);
$sth->bind_columns(\($disease_id, $name));
while ($sth->fetch) {
  if ($name) {
    # check for white space at end of name:
    if ($name =~ /\s$/) {
      print "white space at end of name: '$name'\n";
      $name =~ s/\s+$//;
      print $fh "Update disease set name='$name' where disease_id=$disease_id;\n";
    }
    my $store_name = $name;
    if ($name && $name =~ /\)$/) {
      $name =~ /(.+)(\s*.+\(.+\))$/;
      $new_name = $1;
      print $fh "Update disease set name='$new_name' where disease_id=$disease_id;\n" if ($2);
    } elsif ($name && $name =~ /\]$/) {
      $name =~ /(.+)(\s*.+\(.+\)\s+\[.+\])$/;
      $new_name = $1;
      print $fh "Update disease set name='$new_name' where disease_id=$disease_id;\n" if ($2);
    } elsif ($name && $name =~ /;/) {
  #ULLRICH CONGENITAL MUSCULAR DYSTROPHY 1; UCMD1
      $name =~ /(.+)(;\s*[\w]+)$/;
      $new_name = $1;    
      print $fh "Update disease set name='$new_name' where disease_id=$disease_id;\n" if ($2);
    } else {
      $new_name = $name;
    }  
    if (!$new_name) {
      print $store_name, "\n";
    }
  }
}
$sth->finish();

$fh->close();
