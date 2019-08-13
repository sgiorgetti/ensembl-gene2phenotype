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
  'hgnc_mapping_file=s',
  'gtf_file=s',
  'working_dir=s',
  'test=i',
) or die "Error: Failed to parse command line arguments\n";
die ('A registry_file file is required (--registry_file)') unless (defined($config->{registry_file}));


my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;

my $gfa = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeature');
my $gfda = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');
my $gene_adaptor = $registry->get_adaptor('human', 'core', 'gene');

load_latest_geneset_from_gtf();

delete_genomic_features_not_in_G2P();

# legacy problem where we loaded genes from alternative sequence
update_stable_ids_from_alt_to_chrom();

update_to_new_gene_symbol();

load_new_ensembl_genes();

update_xrefs();

update_search();

delete_outdated_genomic_features();

cleanup();

sub load_latest_geneset_from_gtf {
  my $ensembl_stable_id_2_gene_symbol_from_GTF = read_from_gtf($config->{gtf_file}, $config->{working_dir} . '/ensembl_genes_grch38.txt'); 
  $dbh->do(qq{DROP TABLE IF EXISTS genomic_feature_update;}) or die $dbh->errstr;
  $dbh->do(qq{CREATE TABLE genomic_feature_update LIKE genomic_feature;}) or die $dbh->errstr;
  while (my ($stable_id, $gene_symbol) = each %$ensembl_stable_id_2_gene_symbol_from_GTF) {
    $dbh->do(qq{INSERT INTO genomic_feature_update(gene_symbol, ensembl_stable_id) values("$gene_symbol", "$stable_id");}) or die $dbh->errstr;
  }
}

sub read_from_gtf {
  my $gtf_file = shift;
  my $out_file = shift;
  my $fh = FileHandle->new($gtf_file, 'r');
  my $gene_symbol_2_stable_id = {};
  while (<$fh>) {
    next if(/^#/); #ignore header
    chomp;
    my @values = split/\t/;
    my $attributes = $values[8];
    my @add_attributes = split(";", $attributes);
    # store ids and additional information in second hash
    my %attribs = ();
    foreach my $attr ( @add_attributes ) {
      if ($attr =~ /gene_id/ || $attr =~ /gene_name/ || $attr =~ /gene_biotype/) {
        next unless $attr =~ /^\s*(.+)\s(.+)$/;
        my $type  = $1;
        my $value = $2;
        if ($type  && $value){
          $attribs{$type} = $value;
        }
      }
    }
    my $gene_symbol = $attribs{gene_name};
    $gene_symbol =~ s/"//g;
    my $stable_id = $attribs{gene_id};
    $stable_id =~ s/"//g;
    my $biotype = $attribs{gene_biotype};
    $biotype =~ s/"//g;
    if ($biotype !~ m/pseudogene/ && $biotype ne 'misc_RNA') {
      $gene_symbol_2_stable_id->{$gene_symbol}->{$stable_id} = 1;
    }
  }
  $fh->close();

  my $unique_stable_id_2_gene_symbol = {};

  foreach my $gene_symbol (keys %$gene_symbol_2_stable_id) {
    my @stable_ids = sort keys %{$gene_symbol_2_stable_id->{$gene_symbol}};
    my $stable_id = shift @stable_ids;
    $unique_stable_id_2_gene_symbol->{$stable_id} = $gene_symbol;
  }

  if ($config->{test}) {
    die ('A working_dir must be defiened (--working_dir)') unless (defined($config->{working_dir}));
    my $fh_out = FileHandle->new($out_file, 'w');
    while (my ($stable_id, $gene_symbol) = each %$unique_stable_id_2_gene_symbol) {
      print $fh_out "$stable_id\t$gene_symbol\n";
    }
    $fh_out->close();
  }

  return $unique_stable_id_2_gene_symbol;

}

sub get_gene_symbols_used_by_G2P {
  my $gene_symbols = {};
  my $sth = $dbh->prepare(q{
    SELECT gf.gene_symbol FROM genomic_feature gf
    LEFT JOIN genomic_feature_disease gfd ON
    gf.genomic_feature_id = gfd.genomic_feature_id
    WHERE gfd.genomic_feature_id IS NOT NULL;
  });
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  my ($gene_symbol);
  $sth->bind_columns(\($gene_symbol));
  while (my $row = $sth->fetchrow_arrayref()) {
    $gene_symbols->{$gene_symbol} = 1;
  }
  $sth->finish();
  return $gene_symbols;
}

sub delete_genomic_features_not_in_G2P {
  foreach my $table (qw/genomic_feature genomic_feature_synonym/) {
    $dbh->do(qq{
      DELETE gf.* FROM $table gf
      LEFT JOIN genomic_feature_disease gfd ON
      gf.genomic_feature_id = gfd.genomic_feature_id
      WHERE gfd.genomic_feature_id IS NULL;
    }) or die $dbh->errstr;
  }
}

sub delete_outdated_genomic_features {
    $dbh->do(qq{
      DELETE gf.* FROM genomic_feature gf
      LEFT JOIN genomic_feature_update new ON gf.ensembl_stable_id = new.ensembl_stable_id
      WHERE new.ensembl_stable_id IS NULL
      AND gf.genomic_feature_id NOT IN (SELECT genomic_feature_id from genomic_feature_disease);
    }) or die $dbh->errstr;

    $dbh->do(qq{
      DELETE gfs.* FROM genomic_feature_synonym gfs
      LEFT JOIN genomic_feature gf ON gfs.genomic_feature_id = gf.genomic_feature_id
      WHERE gf.genomic_feature_id IS NULL;
    }) or die $dbh->errstr;
}


sub update_stable_ids_from_alt_to_chrom {
  my $update_ensembl_ids = {};
  my $sth = $dbh->prepare(q{
    SELECT old.genomic_feature_id, old.gene_symbol, new.ensembl_stable_id FROM genomic_feature_update new
    LEFT JOIN genomic_feature old ON new.gene_symbol = old.gene_symbol
    WHERE new.ensembl_stable_id != old.ensembl_stable_id;
  });
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my ($old_genomic_feature_id, $gene_symbol, $new_ensembl_stable_id) = @$row;
    $update_ensembl_ids->{$old_genomic_feature_id} = $new_ensembl_stable_id;
  }
  $sth->finish();
  while (my ($gf_id, $new_ensembl_stable_id) = each %$update_ensembl_ids) {
    print STDERR "UPDATE genomic_feature SET ensembl_stable_id=\"$new_ensembl_stable_id\" WHERE genomic_feature_id=$gf_id;\n";
    $dbh->do(qq{
      UPDATE genomic_feature SET ensembl_stable_id="$new_ensembl_stable_id" WHERE genomic_feature_id=$gf_id;
    }) or die $dbh->errstr;
  }

}

sub update_to_new_gene_symbol {
  # store old gene_symbol as synonym
  my $updates = {}; 
  my $sth = $dbh->prepare(q{
    SELECT new.gene_symbol, old.genomic_feature_id, old.gene_symbol FROM genomic_feature_update new
    LEFT JOIN genomic_feature old ON new.ensembl_stable_id = old.ensembl_stable_id
    WHERE new.gene_symbol != old.gene_symbol;
  });
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my ($new_gene_symbol, $old_genomic_feature_id, $old_gene_symbol) = @$row;
    $updates->{$old_genomic_feature_id}->{$old_gene_symbol} = $new_gene_symbol;
  }
  $sth->finish();

  foreach my $genomic_feature_id (keys %$updates) {
    foreach my $old_gene_symbol (keys %{$updates->{$genomic_feature_id}}) {
      my $new_gene_symbol = $updates->{$genomic_feature_id}->{$old_gene_symbol};
      if ($new_gene_symbol =~ /^AL|C[0-9]*\.[0-9]/) {
        print STDERR "Don't update to new_gene_symbol $old_gene_symbol -> $new_gene_symbol\n";
      } else {
        $dbh->do(qq{
          UPDATE genomic_feature SET gene_symbol="$new_gene_symbol" WHERE genomic_feature_id=$genomic_feature_id;
        }) or die $dbh->errstr;
        $dbh->do(qq{
          INSERT INTO genomic_feature_synonym(genomic_feature_id, name) VALUES($genomic_feature_id, "$old_gene_symbol");
        }) or die $dbh->errstr;
      }
      $dbh->do(qq{
        INSERT IGNORE INTO genomic_feature_synonym(genomic_feature_id, name) VALUES($genomic_feature_id, "$new_gene_symbol");
      }) or die $dbh->errstr;
    }
  }
}

sub load_new_ensembl_genes {
  my $new_gene_symbols;
  my $sth = $dbh->prepare(q{
    SELECT new.gene_symbol, new.ensembl_stable_id FROM genomic_feature_update new
    LEFT JOIN genomic_feature old ON new.ensembl_stable_id = old.ensembl_stable_id
    WHERE old.ensembl_stable_id IS NULL;
  });
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my ($new_gene_symbol, $ensembl_stable_id) = @$row;
    $new_gene_symbols->{$new_gene_symbol}->{$ensembl_stable_id} = 1;
  }
  $sth->finish();

  my $gene_symbols_used_by_G2P = get_gene_symbols_used_by_G2P();

  foreach my $gene_symbol (keys %$new_gene_symbols) {
    my @ensembl_ids = keys %{$new_gene_symbols->{$gene_symbol}};
    my $ensembl_id = $ensembl_ids[0];
    if ($gene_symbols_used_by_G2P->{$gene_symbol}) {
      print STDERR "Stable ID has changed for gene symbol which is already used by G2P ", $gene_symbol, ' ', join(',', keys  %{$new_gene_symbols->{$gene_symbol}}), "\n";  
      $dbh->do(qq{
        UPDATE genomic_feature SET ensembl_stable_id="$ensembl_id" WHERE gene_symbol="$gene_symbol";
      }) 
    } else {
      $dbh->do(qq{
        INSERT INTO genomic_feature(gene_symbol, ensembl_stable_id) VALUES("$gene_symbol", "$ensembl_id");
      }) or die $dbh->errstr;
    }
    if (scalar @ensembl_ids > 1) {
      print STDERR "More than 1 ensembl ids $gene_symbol ", join(',', @ensembl_ids), "\n";
    }
  } 
}

sub update_xrefs {

  my $hgnc_mapping_file = $config->{hgnc_mapping_file};
  my $fh_hgnc = FileHandle->new($hgnc_mapping_file, 'r');
  my $hgnc_mappings = {};
  my $symbol2id_mappings = {};
  while (<$fh_hgnc>) {
    chomp;
    my ($hgnc_id, $symbol, $prev_symbol) = split/\t/;
    if ($prev_symbol) {
      $hgnc_mappings->{$symbol}->{$prev_symbol} = 1;
    }
    $hgnc_id =~ s/HGNC://;
    $symbol2id_mappings->{$symbol} = $hgnc_id;
  }
  $fh_hgnc->close();
  my $GFs = $gfa->fetch_all;

  my $gene_symbols = {};

  foreach my $gf (@$GFs) {
    my $genomic_feature_id = $gf->dbID;
    my @gf_synonyms = @{$gf->get_all_synonyms};
    my $gene_symbol = $gf->gene_symbol;
    if (!$gene_symbol) {
      print 'No gene_symbol for ', $gf->dbID, "\n";
    } else {
      my $hgnc_id = $symbol2id_mappings->{$gene_symbol};
      if ($hgnc_id && (!$gf->hgnc_id || ($gf->hgnc_id && $gf->hgnc_id != $hgnc_id)) ) {
        print STDERR "UPDATE genomic_feature SET hgnc_id=$hgnc_id WHERE genomic_feature_id=$genomic_feature_id;\n";
        $dbh->do(qq{UPDATE genomic_feature SET hgnc_id=$hgnc_id WHERE genomic_feature_id=$genomic_feature_id;}) or die $dbh->errstr unless ($config->{test});
      }
      if ($hgnc_mappings->{$gene_symbol}) {
        foreach my $prev_gene_symbol (keys %{$hgnc_mappings->{$gene_symbol}}) {
          if (! grep( /^$prev_gene_symbol$/, @gf_synonyms ) ) {
            print STDERR "Update prev gene symbols: INSERT INTO genomic_feature_synonym(genomic_feature_id, name) VALUES($genomic_feature_id, '$prev_gene_symbol');\n";
           $dbh->do(qq{INSERT IGNORE INTO genomic_feature_synonym(genomic_feature_id, name) VALUES($genomic_feature_id, '$prev_gene_symbol');}) or die $dbh->errstr unless ($config->{test});
          }
        }
      }
    }
  }
}

sub update_search {
  $dbh->do(qq{TRUNCATE search;}) or die $dbh->errstr unless ($config->{test});
  $dbh->do(qq{INSERT IGNORE INTO search SELECT distinct gene_symbol from genomic_feature;}) or die $dbh->errstr unless ($config->{test});
  $dbh->do(qq{INSERT IGNORE INTO search SELECT distinct name from disease;}) or die $dbh->errstr unless ($config->{test});
  $dbh->do(qq{INSERT IGNORE INTO search SELECT distinct name from genomic_feature_synonym;}) or die $dbh->errstr unless ($config->{test});
}

sub cleanup {
  $dbh->do(qq{DROP TABLE IF EXISTS genomic_feature_update;}) or die $dbh->errstr;
}
