#!/software/bin/perl
use strict;
use warnings;

use DBI;
use FileHandle;
use Getopt::Long;
use Bio::EnsEMBL::Registry;
# perl update_phenotypes.pl -registry_file registry
# perl update_phenotypes.pl >out 2>err
my $config = {};

GetOptions(
  $config,
  'registry_file=s',
  'working_dir=s',
  'new_ontology_db_name=s'
) or die "Error: Failed to parse command line arguments\n";

die ('A registry_file file is required (--registry_file)') unless (defined($config->{registry_file}));
die ('A working_dir must be defiened (--working_dir)') unless (defined($config->{working_dir}));

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;
my $gfda = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');

dump_g2p_phenotypes($config, 'g2p_phenotypes_before_update');
load_new_phenotypes($config);
add_phenotype_id_mapping();
update_to_new_phenotype_id();
dump_g2p_phenotypes($config, 'g2p_phenotypes_after_update');
cleanup();
compare_phenotypes($config, 'g2p_phenotypes_before_update', 'g2p_phenotypes_after_update');

sub dump_g2p_phenotypes {
  my $config = shift;
  my $filename = shift;
  my $working_dir = $config->{working_dir};
  my $fh = FileHandle->new("$working_dir/$filename", 'w');
  my $gfds = $gfda->fetch_all();
  foreach my $gfd (@{$gfds}) {
    my $phenotypes = join(',', sort map {$_->get_Phenotype()->stable_id()} @{$gfd->get_all_GFDPhenotypes()});
    print $fh join(' ', $gfd->dbID, $phenotypes), "\n";
  }
  $fh->close();
}

sub load_new_phenotypes {
  my $config = shift;
  my $new_ontology_db_name = $config->{new_ontology_db_name};

  $dbh->do(qq{CREATE TABLE phenotype_old LIKE phenotype;}) or die $dbh->errstr;
  $dbh->do(qq{INSERT INTO phenotype_old SELECT * FROM phenotype;}) or die $dbh->errstr;

  $dbh->do(qq{TRUNCATE TABLE phenotype;}) or die $dbh->errstr;
  $dbh->do(qq{
    INSERT INTO phenotype(phenotype_id, stable_id, name, source)
    SELECT t.term_id, t.accession, t.name, 'HP' FROM $new_ontology_db_name.term t, $new_ontology_db_name.ontology o
    WHERE t.ontology_id = o.ontology_id
    AND o.name = 'HP'; 
  }) or die $dbh->errstr;

  # find deprecated phenotypes 
  my $sth = $dbh->prepare(qq{
    SELECT count(p_old.phenotype_id) FROM phenotype_old p_old
    LEFT JOIN phenotype p ON p_old.stable_id = p.stable_id
    WHERE p.stable_id IS NULL;
  });
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  my ($count) = $sth->fetchrow_array();
  if ($count) {
    die "$count phenotypes are no longer in the new HP ontology.\n";
  }
}

sub add_phenotype_id_mapping {
  $dbh->do(qq{ALTER TABLE phenotype ADD COLUMN old_phenotype_id int(10) AFTER source;}) or die $dbh->errstr;
  $dbh->do(qq{ALTER TABLE phenotype ADD INDEX `old_phenotype_id` (`old_phenotype_id`);}) or die $dbh->errstr;

  $dbh->do(qq{
    UPDATE phenotype p, phenotype_old p_old SET p.old_phenotype_id = p_old.phenotype_id WHERE p_old.stable_id=p.stable_id;
  }) or die $dbh->errstr;

}

sub update_to_new_phenotype_id {
  # Tables with phenotype_id
  for my $table (qw/genomic_feature_disease_phenotype genomic_feature_disease_phenotype_deleted GFD_phenotype_log/) {
    $dbh->do(qq{ UPDATE $table t, phenotype p SET t.phenotype_id = p.phenotype_id WHERE p.old_phenotype_id = t.phenotype_id; }) or die $dbh->errstr;  
  }
}

sub cleanup {
  $dbh->do(qq{ALTER TABLE phenotype DROP COLUMN old_phenotype_id;}) or die $dbh->errstr;
  $dbh->do(qq{DROP TABLE phenotype_old;}) or die $dbh->errstr;
}

sub compare_phenotypes {
  my $config = shift;
  my $g2p_phenotypes_before_update = shift;
  my $g2p_phenotypes_after_update = shift; 
  my $working_dir = $config->{working_dir};

  my $before_entries = _load_phenotype_file("$working_dir/$g2p_phenotypes_before_update");
  my $after_entries =  _load_phenotype_file("$working_dir/$g2p_phenotypes_after_update");

  foreach my $gfd_id (keys %{$after_entries}) {
    if (!exists $before_entries->{$gfd_id}) {
      print "GFD id ($gfd_id) is not in before update set, which shouldn't happen.\n";
    } else {
      if ($before_entries->{$gfd_id} ne $after_entries->{$gfd_id}) {
        print "Phenotypes changed after update for GFD id ($gfd_id):\n";
        print "    Before: " . $before_entries->{$gfd_id} . "\n";
        print "    After: " . $after_entries->{$gfd_id} . "\n";
      }
    }
  }
}

sub _load_phenotype_file {
  my $file = shift;
  my $entries = {};
  my $fh = FileHandle->new($file, 'r');
  while (<$fh>) {
    chomp;
    my ($gfd_id, $phenotypes) = split(' ', $_);
    $entries->{$gfd_id} = $phenotypes;
  }
  $fh->close();
  return $entries;
}

