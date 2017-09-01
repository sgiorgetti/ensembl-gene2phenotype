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

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle; 

=begin
my $hash = {};
my $sth = $dbh->prepare(q{
  SELECT gfd.genomic_feature_disease_id, gf.gene_symbol, d.name, gfd.panel_attrib FROM genomic_feature_disease gfd, disease d, genomic_feature gf where gfd.genomic_feature_id = gf.genomic_feature_id and gfd.disease_id = d.disease_id;
}, {mysql_use_result => 1});
$sth->execute() or die $dbh->errstr;

my ($gfd_id, $gene_symbol, $disease_name, $panel_attrib);
$sth->bind_columns(\($gfd_id, $gene_symbol, $disease_name, $panel_attrib));
while ($sth->fetch) {
  $hash->{$panel_attrib}->{"$gene_symbol-$disease_name"}->{$gfd_id} = 1;
}
$sth->finish();

foreach my $panel (keys %$hash) {
  foreach my $key (keys %{$hash->{$panel}}) {
    if (scalar keys %{$hash->{$panel}->{$key}} > 1 ) {
      print "$panel $key\n";
    }
  }
}
=end
=cut

my $sth = $dbh->prepare(q{
  SELECT disease_id, name, mim  FROM disease;
}, {mysql_use_result => 1});
$sth->execute() or die $dbh->errstr;

my $name2id = {};
my $id2mim = {};
my $updates = {};
my $deletes = {};

my ($disease_id, $name, $mim);
$sth->bind_columns(\($disease_id, $name, $mim));
while ($sth->fetch) {
  if ($name) {
    $name2id->{$name}->{$disease_id} = 1;
  }
  if ($name && $mim) {
    $id2mim->{$disease_id} = 1;
  }
}
$sth->finish();

my $fh = FileHandle->new($config->{output_file}, 'w');

foreach my $name (keys %$name2id) {
  my @disease_ids = keys %{$name2id->{$name}};
  if (scalar @disease_ids > 1) {
    # choose representative id which preferable has also a mim id
    my $backup_id = $disease_ids[0];
    my $found_id = 0;
    foreach my $id (@disease_ids) {
      if ($id2mim->{$id}) {
        $backup_id = $id;
        $found_id = 1;
        last;
      }
    }
    foreach my $old_id (@disease_ids) {
      if ($old_id != $backup_id) {
        print "$old_id -> $backup_id\n";
        print $fh "UPDATE genomic_feature_disease SET disease_id=$backup_id WHERE disease_id=$old_id;\n";
        print $fh "UPDATE genomic_feature_disease_deleted SET disease_id=$backup_id WHERE disease_id=$old_id;\n";
        print $fh "UPDATE genomic_feature_disease_log SET disease_id=$backup_id WHERE disease_id=$old_id;\n";
#        print $fh "UPDATE disease_ontology_accession SET disease_id=$backup_id WHERE disease_id=$old_id;\n";
        print $fh "DELETE FROM disease where disease_id=$old_id;\n";
      }
    } 
  }
}

$fh->close;
