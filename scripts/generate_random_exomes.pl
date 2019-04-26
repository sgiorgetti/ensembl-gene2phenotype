use strict;
use warnings;

use FileHandle;

# choose 100 random genes
#   choose variants
#   assign genotypes randomly
# choose 2 g2p genes
#   choose variants with low frequencies
#   assign genotypes

my $background_gene_count = 1000;
my $variant_per_gene_count = 20;
my $g2p_gene_count = 1;
my $g2p_variant_per_gene_count = 5;

my $dir = '/hps/nobackup2/production/ensembl/anja/G2P/test_data/';
my $input_dir = "$dir/input/";
my $random_dir = "$dir/random/";
my @vcf_header = ('#CHROM', 'POS', 'ID', 'REF', 'ALT', 'QUAL', 'FILTER', 'INFO', 'FORMAT');

my $background_genes = "$input_dir/background_gene_list_minus_g2p";
my $g2p_genes = "$input_dir/g2p_gene_list";

my $g2p_variants = "$input_dir/suspect_gnomad_grch37_90_vep_filtered.vcf.gz";
my $background_variants = "$input_dir/master_1kg_grch37.vcf.gz";


my $row_count_background_genes = get_file_row_count($background_genes);
my $row_count_g2p_genes = get_file_row_count($g2p_genes);

my $random_numbers = get_random_numbers($background_gene_count, $row_count_background_genes);
my $random_background_regions = get_random_regions($random_numbers, $background_genes);

foreach my $individual (1..100) {
  my $individual_name = "P$individual";

  $random_numbers = get_random_numbers($g2p_gene_count, $row_count_g2p_genes);
  my $random_g2p_regions = get_random_regions($random_numbers, $g2p_genes);

  print_random_vcf($random_background_regions, $random_g2p_regions, $individual_name);
}

sub print_random_vcf {
  my $background_regions = shift;
  my $g2p_regions = shift; 
  my $individual_name = shift;
  my $vcf = "$random_dir/$individual_name.vcf";
  my $fh = FileHandle->new($vcf, 'w');
  print $fh "##fileformat=VCFv4.0\n";
  print $fh "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n";
  print $fh join("\t", @vcf_header) . "\t$individual_name\n";
  my $is_background = 1;
  foreach my $region (@$background_regions) {
    my @rows = @{get_random_tabix_rows($background_variants, $region, $variant_per_gene_count, $is_background)};
    foreach (@rows) {
      print $fh $_;
    }
  }
  # add g2p variants
  $is_background = 0;
  foreach my $region (@$g2p_regions) {
    my @rows = @{get_random_tabix_rows($g2p_variants, $region, $g2p_variant_per_gene_count, $is_background)};
    foreach (@rows) {
      print $fh $_;
    }
  }
  $fh->close; 
  run_cmd("vcf-sort < $random_dir/$individual_name.vcf | bgzip > $random_dir/$individual_name.vcf.gz"); 
  run_cmd("tabix $random_dir/$individual_name.vcf.gz");
  run_cmd("rm $random_dir/$individual_name.vcf");
}

sub get_random_regions {
  my $random_numbers = shift;
  my $file = shift; 
  my $fh = FileHandle->new($file, 'r');
  my $counter = 1;
  my @regions = ();
  while (<$fh>) {
    chomp;
    my @values = split;
    my ($chr, $start, $end) = ($values[0], $values[1], $values[2]);
    if (grep {$_ == $counter} @$random_numbers) {
      push @regions, "$chr:$start-$end";
    }
    $counter++
  }
  $fh->close;
  return \@regions;
}


sub get_random_numbers {
  my $random_number_count = shift;
  my $max_value = shift;
  my @random_numbers = ();
  while (scalar @random_numbers <= $random_number_count) {
    push @random_numbers, int(rand($max_value)) + 1;
  }
  return \@random_numbers;
}

sub get_file_row_count {
  my $file = shift;
  my ($all_entries) = split(' ', `wc -l $file`); 
  return $all_entries;
}

sub get_tabix_row_count {
  my $file = shift;
  my $region = shift;
  my @rows = `tabix $file $region`;
  return scalar @rows;
}

sub get_tabix_rows {
  my $file = shift;
  my $region = shift;
  my @rows = `tabix $file $region`;
  return \@rows;
}

sub get_random_tabix_rows {
  my $file = shift;
  my $region = shift;
  my $variant_count = shift;
  my $is_background = shift;
  my $row_count = get_tabix_row_count($file, $region);
  my $random_numbers = get_random_numbers($variant_count, $row_count);
  my $tabix_rows = get_tabix_rows($file, $region);
  my $count = 1;
  my @rows = ();
  my @gts = ($is_background) ? ('./.', '1/0', '0/1', '1/1') : ('0/1', '1/1');
  foreach my $tabix_row (@$tabix_rows) {
    if (grep {$count == $_} @$random_numbers) {
      chomp($tabix_row);
      my @row = split/\t/, $tabix_row;
      #CHROM POS ID REF ALT QUAL FILTER INFO
      push @rows, join("\t", $row[0],  $row[1], $row[2], $row[3], $row[4], '.', '.', '.') . "\tGT\t" . $gts[ rand @gts ] . "\n";
    }
    $count++;
  } 
  return \@rows;
}

sub run_cmd {
  my $cmd = shift;
  if (my $return_value = system($cmd)) {
    $return_value >>= 8;
    die "system($cmd) failed: $return_value";
  }
}

