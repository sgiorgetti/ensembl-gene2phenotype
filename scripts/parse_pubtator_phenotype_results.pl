use strict;
use warnings;

use FileHandle;
use Bio::EnsEMBL::Registry;
use Array::Utils qw(:all);
use Getopt::Long;
use Text::CSV;

my $config = {};
GetOptions(
  $config,
  'registry_file=s',
  'working_dir=s',
  'file_mesh_ids_linked_to_GFD=s',
  'file_disease2pubtator=s',
  'file_oxo_mappings_results=s',
  'file_oxo_mappings_processed=s',
  'file_all_mesh_terms=s',
  'file_c_mesh_terms=s',
  'file_d_mesh_terms=s',
) or die "Error: Failed to parse command line arguments\n";
die ('A registry_file file is required (--registry_file)') unless (defined($config->{registry_file}));

# file_mesh_ids_linked_to_GFD
# file_disease2pubtator
# file_mesh_ids_linked_to_GFD
# file_oxo_mappings_results mappings.csv
# file_oxo_mappings_processed ebi_oxo_mappings
# file_all_mesh_terms
# file_c_mesh_terms file_d_mesh_terms
# ftp://nlmpubs.nlm.nih.gov/online/mesh/MESH_FILES/asciimesh/
my $registry_file = $config->{registry_file};
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all($registry_file);
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;

my $pipline_step = get_pipline_step($config);

my $g2p_pmids = get_pmids_linked_to_GFDs();

# 1. Export MESH ids for all publications that have been assigned to a genomic feature disease pair

if ($pipline_step eq 'export_mesh_ids') {
  export_mesh_ids($config);
  update_pipline_step($config, 'export_mesh_ids');
  print STDERR "Export mesh ids is completed. Use file_mesh_ids_linked_to_GFD as input for oxo mapping service.\n";
  print STDERR "Run EBI oxo service https://www.ebi.ac.uk/spot/oxo/index with mapping distance 3.\n";
  print STDERR "Run again to resume loading pubtator phenotype results. Update file_oxo_mappings_results.\n";
}

# 2. Run EBI OXO service

if ($pipline_step eq 'resume_loading_pubtator_phenotype_results') {
# 3. parse EBI OXO mapping results: mappings.csv to ebi_oxo_mappings.txt
#  parse_oxo_mappings($config);
# 4. Parse all MESH terms
#  retrieve_all_mesh_terms($config);
# 5. Add new mesh terms to phenotype table
#  add_new_mesh_terms($config);
# 6. Populate phenotype_mapping table
#  populate_phenotype_mapping_table($config);
# 7. Populate text_mining_disease table
  populate_text_mining_disease_table($config);
# 8. clean up pipline_step file
#  remove_pipline_step_file($config);
  print STDERR "Completed loading pubtator phenotype results\n";
}

sub export_mesh_ids {
  my $config = shift;
  my $write_mesh_ids_file = $config->{file_mesh_ids_linked_to_GFD};
  my $pubtator_phenotypes = $config->{file_disease2pubtator};

  my $fh_out = FileHandle->new($write_mesh_ids_file, 'w');
  my $fh = FileHandle->new($pubtator_phenotypes, 'r');
  my $meshIDs = {};
  while (<$fh>) {
    chomp;
    next if (/^PMID/);
  #PMID    MeshID  Mentions        Resource
    my ($pmid, $type, $meshID, $mentions, $resource) = split/\t/;
    next if (!$g2p_pmids->{$pmid});
    next if ($meshID =~ /^OMIM/);
    $meshIDs->{$meshID} = 1;
  }
  $fh->close;
  foreach my $meshID (keys %$meshIDs) {
    print $fh_out "$meshID\n";
  }
  $fh_out->close;
}

sub get_pmids_linked_to_GFDs {
  my $g2p_pmids = {};
  my $sth = $dbh->prepare(q{
    SELECT distinct p.pmid, p.publication_id from genomic_feature_disease_publication gfdp, publication p WHERE gfdp.publication_id = p.publication_id;
  }, {mysql_use_result => 1});
  $sth->execute() or die $dbh->errstr;
  my ($pmid, $publication_id);
  $sth->bind_columns(\($pmid, $publication_id));
  while ($sth->fetch) {
    $g2p_pmids->{$pmid} = $publication_id;
  }
  $sth->finish;
  return $g2p_pmids;
}

sub parse_oxo_mappings {
  my $config = shift;
  my $read_oxo_mappings = $config->{file_oxo_mappings_results}; # mappings.csv
  my $write_oxo_mappings = $config->{file_oxo_mappings_processed}; # ebi_oxo_mappings
  my $fh = FileHandle->new($read_oxo_mappings, 'r');
  my $meshIDs = {};

  while (<$fh>) {
    chomp;
    my @row = split/\t/;
    my $curie_id = $row[0];
    my $label = $row[1];
    my $mapped_curie = $row[2];
    my $mapped_label = $row[3];
    $meshIDs->{$curie_id}->{label} = $label;
    $meshIDs->{$curie_id}->{mappings}->{$mapped_curie} = $mapped_label;
  }
  $fh->close;

  $fh = FileHandle->new($write_oxo_mappings, 'w');
  foreach my $meshID (keys %$meshIDs) {
    my $label = $meshIDs->{$meshID}->{label};
    my $mappings = join(',', keys %{$meshIDs->{$meshID}->{mappings}});
    print $fh "$meshID\t$label\t$mappings\n";
  }
  $fh->close;
}

sub parse_oxo_mappings_csv {
  my $config = shift;
  my $read_oxo_mappings = $config->{file_oxo_mappings_results}; # mappings.csv
  my $write_oxo_mappings = $config->{file_oxo_mappings_processed}; # ebi_oxo_mappings
  my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
              or die "Cannot use CSV: ".Text::CSV->error_diag ();

  open my $fh, "<:encoding(utf8)", $read_oxo_mappings or die "$read_oxo_mappings: $!";
  #curie_id label mapped_curie  mapped_label  mapping_source_prefix mapping_target_prefix distance
  my $mashIDs = {};
  while ( my $row = $csv->getline( $fh ) ) {
    next if ($row->[0] eq 'curie_id');
    my $curie_id = $row->[0];
    next if ($curie_id !~ /^MeSH/);
    my $label = $row->[1];
    my $mapped_curie = $row->[2];
    my $mapped_label = $row->[3];
    $mashIDs->{$curie_id}->{label} = $label;
    $mashIDs->{$curie_id}->{mappings}->{$mapped_curie} = $mapped_label;
  }
  $csv->eof or $csv->error_diag();
  close $fh;

  $fh = FileHandle->new($write_oxo_mappings, 'w');
  foreach my $mashID (keys %$mashIDs) {
    my $label = $mashIDs->{$mashID}->{label};
    my $mappings = join(',', keys %{$mashIDs->{$mashID}->{mappings}});
    print $fh "$mashID\t$label\t$mappings\n";
  }
  $fh->close;
}

sub retrieve_all_mesh_terms {
  my $config = shift;

  my $write_all_mesh_terms = $config->{file_all_mesh_terms}; 
  my $read_c_mesh_terms = $config->{file_c_mesh_terms};
  my $read_d_mesh_terms = $config->{file_d_mesh_terms};

  my $fh_out = FileHandle->new($write_all_mesh_terms, 'w');

  foreach my $file ($read_c_mesh_terms, $read_d_mesh_terms) {
    my $fh = FileHandle->new($file, 'r');
    my $found_nm = 0;
    my $found_ui = 0;
    my $nm = '';
    my $ui = '';
    while (<$fh>) {
      chomp;
      my $record = $_;

      if ($record =~ /^NM\s+|MH\s+/) {
        $nm = get_value($record);
        $found_nm = 1;
      }
      if ($record =~ /^UI/) {
        $ui = get_value($record);
        $found_ui = 1;
      }
      if ($record eq '*NEWRECORD') {
        if ($found_nm && $found_ui) {
          print $fh_out "MESH:$ui\t$nm\n";
          ($found_nm, $found_ui, $nm, $ui) = (0, 0, '', '');
        }
      }
    }
    $fh->close;
  }
  $fh_out->close;
}

sub get_value {
  my $pair = shift;
  my ($key, $value) = split(' = ', $pair);
  return $value;
}


sub add_new_mesh_terms {
  my $config = shift;
  my $existing_mesh_mappings = _get_stable_id_to_phenotype_id_mappings('MESH');

  my $file_all_mesh_terms = $config->{file_all_mesh_terms};
  my $file_mesh_ids_linked_to_GFD = $config->{file_mesh_ids_linked_to_GFD};

  my $all_mesh_terms = {};

  my $fh = FileHandle->new($file_all_mesh_terms, 'r');
  while (<$fh>) {
    chomp;
    my ($mesh_id, $term) = split/\t/;
    $all_mesh_terms->{$mesh_id} = $term;
  }

  $fh->close;

  $fh = FileHandle->new($file_mesh_ids_linked_to_GFD, 'r');

  while (<$fh>) {
    chomp;
    next if (!/^MESH/);
    next if ($existing_mesh_mappings->{$_});
    my $term = $all_mesh_terms->{$_};
    if (!$term) {
      $dbh->do(qq{INSERT INTO phenotype(stable_id, source) VALUES("$_", "MESH");}) or die $dbh->errstr;
    } else {
      $dbh->do(qq{INSERT INTO phenotype(stable_id, name, source) VALUES("$_", "$term", "MESH");}) or die $dbh->errstr;
    }
  }
  $fh->close;
}

sub populate_phenotype_mapping_table {
  my $config = shift;

  my $mesh_ids = _get_stable_id_to_phenotype_id_mappings('MESH');;
  my $hpo_ids = _get_stable_id_to_phenotype_id_mappings('HP');

  my $file_ebi_oxo_mappings = $config->{file_oxo_mappings_processed};
  my $fh = FileHandle->new($file_ebi_oxo_mappings, 'r');

  $dbh->do(qq{Truncate table phenotype_mapping;}) or die $dbh->errstr;

  my $stored_in_db = {};
  while (<$fh>) {
    chomp;
    my ($stable_id, $name, $hpo) = split/\t/;
    $stable_id =~ s/MeSH/MESH/;
    my $mesh_id = $mesh_ids->{$stable_id};
    foreach my $hpo_id (split(',', $hpo)) {
      my $phenotype_id = $hpo_ids->{$hpo_id};
      if (!$phenotype_id || !$mesh_id) {
        print STDERR $hpo_id, "\n";
      } else {
        $dbh->do(qq{INSERT INTO phenotype_mapping(mesh_id, phenotype_id) VALUES($mesh_id, $phenotype_id);}) or die $dbh->errstr;
      }
    }
  }

  $fh->close;
}

sub populate_text_mining_disease_table_from_file {
  my $config = shift; 
  print "populate_text_mining_disease_table\n"; 
  my $file_disease2pubtator = $config->{file_disease2pubtator};

  my $mesh_ids = _get_stable_id_to_phenotype_id_mappings("MESH");

  $dbh->do(qq{Truncate table text_mining_disease;}) or die $dbh->errstr;

  my $fh = FileHandle->new($file_disease2pubtator, 'r');

  while (<$fh>) {
    chomp;
    next if (/^PMID/);
    my ($pmid, $type, $meshID, $mentions, $resource) = split/\t/;
    next if (!$g2p_pmids->{$pmid});
    next if ($meshID !~ /^MESH/);
    my $publication_id = $g2p_pmids->{$pmid};
    my $mesh_id = $mesh_ids->{$meshID};
    $mentions =~ s/"//g;
   $dbh->do(qq{INSERT INTO text_mining_disease(publication_id, mesh_id, annotated_text, source) VALUES($publication_id, $mesh_id, "$mentions", "$resource");}) or die $dbh->errstr;
  }
  $fh->close;
}

sub populate_text_mining_disease_table {
  my $config = shift; 

  my $file_disease2pubtator = $config->{file_disease2pubtator};

  my $mesh_ids = _get_stable_id_to_phenotype_id_mappings('MESH');

  $dbh->do(qq{Truncate table text_mining_disease;}) or die $dbh->errstr;

  my $fh = FileHandle->new($file_disease2pubtator, 'r');

  while (<$fh>) {
    chomp;
    next if (/^PMID/);
    my ($pmid, $type, $meshID, $mentions, $resource) = split/\t/;
    next if (!$g2p_pmids->{$pmid});
    next if ($meshID !~ /^MESH/);
    my $publication_id = $g2p_pmids->{$pmid};
    my $mesh_id = $mesh_ids->{$meshID};
    $mentions =~ s/"//g;
   $dbh->do(qq{INSERT INTO text_mining_disease(publication_id, mesh_id, annotated_text, source) VALUES($publication_id, $mesh_id, "$mentions", "$resource");}) or die $dbh->errstr;
  }
  $fh->close;
}

sub update_pipline_step {
  my $config = shift;
  my $pipline_step = shift;
  my $working_dir = $config->{working_dir};
  my $fh = FileHandle->new("$working_dir/pipline_step", 'w');
  print $fh "$pipline_step";
  $fh->close;
}

sub remove_pipline_step_file {
  my $config = shift;
  my $working_dir = $config->{working_dir};
  unlink "$working_dir/pipline_step" or warn "Could not unlink $working_dir/pipline_step: $!";
}

sub get_pipline_step {
  my $config = shift;
  my $working_dir = $config->{working_dir};
  my $file = "$working_dir/pipline_step";
  if (! -e $file)  {
    return 'export_mesh_ids'; 
  } else {
    my $fh = FileHandle->new("$working_dir/pipline_step", 'r');
    my $file_content = do { local $/; <$fh> };
    $fh->close();
    if ($file_content =~ /^export_mesh_ids/) {
      return 'resume_loading_pubtator_phenotype_results';
    }
  }
}

sub _get_stable_id_to_phenotype_id_mappings {
  my $source = shift;
  my $mappings = {};
  my $sth = $dbh->prepare(qq{
    SELECT phenotype_id, stable_id from phenotype WHERE source="$source";
  }, {mysql_use_result => 1});
  $sth->execute() or die $dbh->errstr;
  my ($phenotype_id, $stable_id);
  $sth->bind_columns(\($phenotype_id, $stable_id));
  while ($sth->fetch) {
    $mappings->{$stable_id} = $phenotype_id;
  }
  $sth->finish;
  return $mappings; 
}




