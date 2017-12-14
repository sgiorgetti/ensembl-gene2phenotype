use strict;
use warnings;

use FileHandle;
use Bio::EnsEMBL::Registry;
use Array::Utils qw(:all);
my $working_dir = '/hps/nobackup/production/ensembl/anja/G2P/text_mining/';
my $registry_file = "$working_dir/registry_file_live";
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all($registry_file);
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;

my $g2p_pmids = {};
my $g2p_pmid_2_gene_symbol = {};

my $amino_acid_code = {
  'A' => 'Ala',
  'R' => 'Arg',
  'N' => 'Asn',
  'D' => 'Asp',
  'B' => 'Asx',
  'C' => 'Cys',
  'E' => 'Glu',
  'Q' => 'Gln',
  'Z' => 'Glx',
  'G' => 'Gly',
  'H' => 'His',
  'I' => 'Ile',
  'L' => 'Leu',
  'K' => 'Lys',
  'M' => 'Met',
  'F' => 'Phe',
  'P' => 'Pro',
  'S' => 'Ser',
  'T' => 'Thr',
  'W' => 'Trp',
  'Y' => 'Tyr',
  'V' => 'Val', 
  'X' => 'Xaa',
};

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

print scalar keys %$g2p_pmids, "\n";

$sth = $dbh->prepare(q{SELECT distinct pg.pmid, gf.gene_symbol from genomic_feature_disease_publication gfdp, text_mining_pmid_gene pg, genomic_feature gf where gfdp.publication_id = pg.publication_id and pg.genomic_feature_id = gf.genomic_feature_id}, {mysql_use_result => 1});
$sth->execute() or die $dbh->errstr;
my ($gene_symbol);
$sth->bind_columns(\($pmid, $gene_symbol));
while ($sth->fetch) {
  $g2p_pmid_2_gene_symbol->{$pmid}->{$gene_symbol} = 1;
}
$sth->finish;

print scalar keys %$g2p_pmid_2_gene_symbol, "\n";


my $fh_out = FileHandle->new("$working_dir/results/production_gene_hgvs_pmid_20171213", 'w');

my $fh = FileHandle->new("$working_dir/data/mutation2pubtator", 'r');

my $coord_types = {};
my $mutation_types = {};

my $dbsnp = 0;
my $dbsnp_tmvar = 0;
my $tmvar = 0;

#PMID  Components  Mentions  Resource
my $variant_results = {};
my $hgvs_results = {};
while (<$fh>) {
  chomp;
  next if (/^PMID/);
  my ($pmid, $components, $mentions, $resources) = split/\t/;
  next if (!$g2p_pmids->{$pmid});
  $resources = cleanup_resources($resources);
  my $hgvs_components = hgvs_components($components);
  if ($hgvs_components) {
    $hgvs_results->{$pmid}->{$hgvs_components}->{$resources} = 1;
  }
  my $variant_identifiers = variant_identifiers($components);
  foreach my $variant (@$variant_identifiers) {
    $variant_results->{$pmid}->{$variant}->{$resources} = 1;
  }
}

my @hgvs_pmids = keys %$hgvs_results;
my @variant_pmids = keys %$variant_results;

my @union = intersect(@hgvs_pmids, @variant_pmids);

print STDERR 'HGVS results ', scalar keys %$hgvs_results, "\n";
print STDERR 'Variant results ', scalar keys %$variant_results, "\n";
print STDERR 'Union ', scalar @union, "\n";



foreach my $pmid (keys %$hgvs_results) {
  if ($g2p_pmid_2_gene_symbol->{$pmid}) {
    my $variants = join(',', keys %{$variant_results->{$pmid}}) || 'NA';
    my @gene_symbols = keys %{$g2p_pmid_2_gene_symbol->{$pmid}};
    my @passed_hgvs = ();
    my @failed_hgvs = ();
    foreach my $hgvs_components (keys %{$hgvs_results->{$pmid}}) {
      my $hgvs = parse_hgvs($hgvs_components);
      if ($hgvs) {
        push @passed_hgvs, $hgvs;
      } else {
        push @failed_hgvs, $hgvs_components;
      }
    }
    if ($variants eq 'NA') {
      print $fh_out "$pmid\t$variants\t" . join(',', @gene_symbols) . "\t" . join(',', @passed_hgvs) . "\t" . join(',', @failed_hgvs) .  "\n";
    }
  }
}


$fh->close;
$fh_out->close;


=begin
my $reordered_results = {};
foreach my $pmid (keys %$results) {
  foreach my $source (keys %{$results->{$pmid}}) {
    my $variant = $results->{$pmid}->{$source};
    $reordered_results->{$variant}->{$source} = 1;
  }
}
my $sources_counts = {};
foreach my $pmid (keys %$results) {
  my $sources = join(',', sort keys %{$results->{$pmid}});
  $sources_counts->{$sources}++;
}
foreach my $source (sort { $sources_counts->{$a} <=> $sources_counts->{$b} } keys %$sources_counts) {
  print STDERR $source, ' ', $sources_counts->{$source}, "\n";
}
=end
=cut

sub parse_hgvs {
  my $components = shift;
  my @split_components = split('\|', $components);
 
  if (scalar @split_components == 5) {
    my $coord_type = $split_components[0];
    my $mutation_type = $split_components[1];
    my $ref_sequence = $split_components[2];
    my $alt_sequence = $split_components[4];
    my $location = $split_components[3];
    if (is_number($location) && is_literal($ref_sequence) && is_literal($alt_sequence)) {
      if ($mutation_type eq 'SUB') {
        if ($coord_type eq 'p') {
          $ref_sequence = to_3_letter_code($ref_sequence);
          $alt_sequence = to_3_letter_code($alt_sequence);
          if ($ref_sequence && $alt_sequence) {
            return "$coord_type.$ref_sequence$location$alt_sequence";
          } else {
            return undef;
          }
        } elsif ($coord_type eq 'c') {
          return "$coord_type.$location$ref_sequence>$alt_sequence";
        } 
      } else {
        return undef;
      }
    }
  } elsif (scalar @split_components == 4) {
#p|DEL|295|I
#c|DEL|322|C
#c|INS|322|C
#p|DEL|396|C
    my $coord_type = $split_components[0];
    my $mutation_type = $split_components[1];
    my $location = $split_components[2];
    my $alt_sequence = $split_components[3];
    if ($mutation_type eq 'DEL' || $mutation_type eq 'INS') {
      if (is_number($location) && (is_literal($alt_sequence) || is_number($alt_sequence))) {
        if ($coord_type eq 'c') {
          return "$coord_type.$location$mutation_type$alt_sequence";
        } elsif ($coord_type eq 'p') {
          $alt_sequence = to_3_letter_code($alt_sequence);
          if ($alt_sequence) {
            return "$coord_type.$location$mutation_type$alt_sequence";
          } else {
            return "$coord_type.$location$mutation_type";
          }
        }
      }
    }
  } elsif (scalar @split_components == 3) {
    my $coord_type = $split_components[0];
    my $mutation_type = $split_components[1];
    my $location = $split_components[2];
    return "$coord_type.$location$mutation_type";
  }
  else {
    return undef;
  }
  return undef;
}

sub hgvs_components {
  my $components = shift;
  if ($components =~ /;/) {
    my @values = split(';', $components);
    if (scalar @values != 2) {
      warn "Got more than 2 components after splitting $components\n";
      return undef;
    }
    return $values[0];
  } elsif ($components =~ /^(rs|Rs|RS|SS|ss)(\d+)$/) {
    return undef;
  } else {
    return $components;
  }
}

sub variant_identifiers {
  my $components = shift;
 
  my @results = ();

  if ($components =~ /;/) {
    my @values = split(';', $components);
    if (scalar @values != 2) {
      warn "Got more than 2 components after splitting $components\n";
      return undef;
    }
    my $var_ids = $values[1];
    $var_ids =~ s/RS#://;
    foreach my $number (split('\|', $var_ids)) {
      push @results, "rs$number";
    }
    return \@results;
  } 

  elsif ($components =~ /^(rs|Rs|RS|SS|ss)(\d+)$/) {
    my $lc_mentions = lc $components;
    push @results, $lc_mentions;
    return \@results;
  }

  else {
    return undef;
  }
}

sub is_number {
  my $number = shift;
  return ($number =~ m/^([0-9]|\,|\_|\+)+$/);
}

sub is_literal {
  my $literal = shift;
  return ($literal =~ m/^[a-zA-Z]+$/);
}

sub is_empty {
  my $is_empty = shift;
  return !defined($is_empty);
}

sub to_3_letter_code {
  my $sequence = shift;
  my @letters = split('', $sequence);
  my @new_sequence = ();
  foreach my $letter (@letters) {
    my $aa = $amino_acid_code->{$letter};
    if (!$aa) {
      return undef;
    }
    push @new_sequence, $aa;
  }
  return join('', @new_sequence);
}

sub cleanup_resources {
  my $source = shift;
  my @sources = split('\|', $source);
  return join('|', sort @sources); 
}
