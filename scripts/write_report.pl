#!/usr/bin/env perl
# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.



=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

  Questions may also be sent to the Ensembl help desk at
  <http://www.ensembl.org/Help/Contact>.

=cut
use strict;
use Getopt::Long;
use FileHandle;
use Bio::EnsEMBL::Registry;
use CGI qw/:standard/;

my $args = scalar @ARGV;
my $config = {};
GetOptions(
    $config,
    'help|h',            # displays help message
    'log_dir=s',
    'html_report=s',
    'txt_report=s',
) or die "ERROR: Failed to parse command-line flags\n";

if (defined($config->{help}) || !$args ) {
  &usage;
  exit(0);
}

my $log_dir = $config->{log_dir};

die "Not a directory $config->{log_dir}" if (!-d $config->{log_dir});

my $html_output_file = $config->{html_report} || 'g2p_report_file.html';

my $txt_output_file = $config->{txt_report} || 'g2p_report_file.txt';

my @frequencies_header = qw/AFR AMR EAS EUR SAS AA EA ExAC ExAC_AFR ExAC_AMR ExAC_Adj ExAC_EAS ExAC_FIN ExAC_NFE ExAC_OTH ExAC_SAS/;

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
  -host => 'ensembldb.ensembl.org',
  -user => 'anonymous',
  -port => 3337,
);

my $transcript_adaptor = $registry->get_adaptor('human', 'core', 'transcript');

my $genes = {};
my $individuals = {};
my $complete_genes = {};
my $g2p_list = {};
my $in_vcf_file = {};
my $transcripts = {};
my $canonical_transcripts = {};

my $cache = {};
my $acting_ars = {};

my @files = <$log_dir/*>;

foreach my $file (@files) {
  my $fh = FileHandle->new($file, 'r');
  while (<$fh>) {
    chomp;
    if (/^G2P_list/) {
      my ($flag, $gene_symbol, $DDD_category) = split/\t/;
      $g2p_list->{$gene_symbol} = 1;
    } elsif (/^G2P_in_vcf/) {
      my ($flag, $gene_symbol) = split/\t/;
      $in_vcf_file->{$gene_symbol} = 1;
    } elsif (/^G2P_complete/) {
      my ($flag, $gene_symbol, $tr_stable_id, $individual, $vf_name, $ars, $zyg) = split/\t/;
      foreach my $ar (split(',', $ars)) {
        if ($ar eq 'biallelic') {
          # homozygous, report complete
          if (uc($zyg) eq 'HOM') {
            $complete_genes->{$gene_symbol}->{$individual}->{$tr_stable_id} = 1;
            $acting_ars->{$gene_symbol}->{$individual}->{$ar} = 1;
          }
          # heterozygous
          # we need to cache that we've observed one
          elsif (uc($zyg) eq 'HET') {
            if (scalar keys %{$cache->{$individual}->{$tr_stable_id}} > 0) {
              $complete_genes->{$gene_symbol}->{$individual}->{$tr_stable_id} = 1;
              $acting_ars->{$gene_symbol}->{$individual}->{$ar} = 1;
            }
            $cache->{$individual}->{$tr_stable_id}->{$vf_name}++;
          }
        }
        # monoallelic genes require only one allele
        elsif ($ar eq 'monoallelic' || $ar eq 'x-linked dominant' || $ar eq 'monoallelic (X; hemizygous)' || $ar eq 'x-linked over-dominance') {
          $complete_genes->{$gene_symbol}->{$individual}->{$tr_stable_id} = 1;
          $acting_ars->{$gene_symbol}->{$individual}->{$ar} = 1;
        }
      }
    } elsif (/^G2P_flag/) {
      my ($flag, $gene_symbol, $tr_stable_id, $individual, $vf_name, $g2p_data) = split/\t/;
      $genes->{$gene_symbol}->{"$individual\t$vf_name"}->{$tr_stable_id} = $g2p_data;
      $individuals->{$individual}->{$gene_symbol}->{$vf_name}->{$tr_stable_id} = $g2p_data;
    } else {

    }
  }
  $fh->close();
}

my $count_g2p_genes = keys %$g2p_list;
my $count_in_vcf_file = keys %$in_vcf_file;
my $count_complete_genes = keys %$complete_genes;

my $chart_data = {};
my $txt_output_data = {};
foreach my $individual (keys %$individuals) {
  foreach my $gene_symbol (keys %{$individuals->{$individual}}) {
    foreach my $vf_name (keys %{$individuals->{$individual}->{$gene_symbol}}) {
      foreach my $tr_stable_id (keys %{$individuals->{$individual}->{$gene_symbol}->{$vf_name}}) {
        if ($complete_genes->{$gene_symbol}->{$individual}->{$tr_stable_id}) {
          my $data = $individuals->{$individual}->{$gene_symbol}->{$vf_name}->{$tr_stable_id};
          my $hash = {};
          foreach my $pair (split/;/, $data) {
            my ($key, $value) = split('=', $pair, 2);
            $value ||= '';
            $hash->{$key} = $value;
          }
          my $vf_location = $hash->{vf_location};
          my $existing_name = $hash->{existing_name};
          my $refseq = $hash->{refseq};
          my $failed = $hash->{failed};
          my $clin_sign = $hash->{clin_sig};
          my $novel = $hash->{novel};
          my $hgvs_t = $hash->{hgvs_t};
          my $hgvs_p = $hash->{hgvs_p}; 
          my $allelic_requirement = $hash->{allele_requirement};
          my $observed_allelic_requirement = $hash->{ar_in_g2pdb};
          my $consequence_types = $hash->{consequence_types};
          my $zygosity = $hash->{zyg};
          my $sift_score = $hash->{sift_score} || '0.0';
          my $sift_prediction = $hash->{sift_prediction};
          my $sift = 'NA';
          if ($sift_prediction ne 'NA') {
            $sift = "$sift_prediction(" . "$sift_score)";
          }
          my $polyphen_score = $hash->{polyphen_score} || '0.0';
          my $polyphen_prediction = $hash->{polyphen_prediction};
          my $polyphen = 'NA';
          if ($polyphen_prediction ne 'NA') {
            $polyphen = "$polyphen_prediction($polyphen_score)";
          }
          my %frequencies_hash = ();
          if ($hash->{frequencies} ne 'NA') {
            %frequencies_hash = split /[,=]/, $hash->{frequencies};
          }
          my @frequencies = ();
          my @txt_output_frequencies = ();
          foreach my $population (@frequencies_header) {
            my $frequency = $frequencies_hash{$population};
            push @frequencies, "$frequency";
            if ($frequency) {
              push @txt_output_frequencies, "$population=$frequency";
            }
          }         
          my $acting_ar = join(',', sort keys (%{$acting_ars->{$gene_symbol}->{$individual}}));
      
          my $is_canonical = 0; 
          if ($hash->{is_canonical}) {
            $is_canonical = ($hash->{is_canonical} eq 'yes') ? 1 : 0;
          } else {
            if ($transcripts->{$tr_stable_id}) {
              $is_canonical = 1 if ($canonical_transcripts->{$tr_stable_id});
            } else {
              my $transcript = $transcript_adaptor->fetch_by_stable_id($tr_stable_id);
              $is_canonical = $transcript->is_canonical();
              $transcripts->{$tr_stable_id} = 1;
              $canonical_transcripts->{$tr_stable_id} = 1 if ($is_canonical);
            }
          }
          my ($location, $alleles) = split(' ', $vf_location);
          $location =~ s/\-/:/;
          $alleles =~ s/\//:/;
          my $txt_output_variant = "$location:$alleles:$zygosity:$consequence_types";
          if (@txt_output_frequencies) {
            $txt_output_variant .= ':' . join(',', @txt_output_frequencies);
          }
          $txt_output_data->{$individual}->{$gene_symbol}->{$tr_stable_id}->{is_canonical} = $is_canonical;
          $txt_output_data->{$individual}->{$gene_symbol}->{$tr_stable_id}->{acting_ar} = $acting_ar;
          push @{$txt_output_data->{$individual}->{$gene_symbol}->{$tr_stable_id}->{variants}}, $txt_output_variant;
          push @{$chart_data->{$individual}}, [[$vf_location, $gene_symbol, $tr_stable_id, $hgvs_t, $hgvs_p, $refseq, $vf_name, $existing_name, $novel, $failed, $clin_sign, $consequence_types, $observed_allelic_requirement, $acting_ar, $zygosity, $sift, $polyphen, @frequencies], $is_canonical];

        } 
      }    
    }
  }
}

# write txt output
my $fh_txt = FileHandle->new($txt_output_file, 'w');
foreach my $individual (keys %$txt_output_data) {
  foreach my $gene_symbol (keys %{$txt_output_data->{$individual}}) {
    foreach my $tr_stable_id (keys %{$txt_output_data->{$individual}->{$gene_symbol}}) { 
      my $is_canonical = $txt_output_data->{$individual}->{$gene_symbol}->{$tr_stable_id}->{is_canonical};
      my $canonical_tag = ($is_canonical) ? 'is_canonical' : 'not_canonical'; 
      my $acting_ar = $txt_output_data->{$individual}->{$gene_symbol}->{$tr_stable_id}->{acting_ar};
      my $variants = join(';', @{$txt_output_data->{$individual}->{$gene_symbol}->{$tr_stable_id}->{variants}});
      print $fh_txt "$individual $gene_symbol $tr_stable_id $canonical_tag $acting_ar $variants\n";  
    }
  }
}
$fh_txt->close();

my @charts = ();
my $count = 1;
  my @header = ('Variant location and alleles (REF/ALT)', 'Gene symbol', 'Transcript stable ID', 'HGVS transcript', 'HGVS protein', 'RefSeq IDs', 'Variant name', 'Existing name', 'Novel variant', 'Has been failed by Ensembl', 'ClinVar annotation', 'Consequence types', 'Allelic requirement (all observed in G2P DB)', 'GENE REQ', 'Zygosity', 'SIFT', 'PolyPhen', @frequencies_header);

foreach my $individual (sort keys %$chart_data) {
  push @charts, {
    type => 'Table',
    title => $individual,
    data => $chart_data->{$individual},
    sort => 'value',
  };
  $count++;
}

my $fh_out = FileHandle->new($html_output_file, 'w');
print $fh_out stats_html_head(\@charts);
print $fh_out "<div class='main_content'>";

print $fh_out p("G2P genes: $count_g2p_genes");
print $fh_out p("G2P genes in input VCF file: $count_in_vcf_file");
print $fh_out p("G2P complete genes in input VCF file: $count_complete_genes");

print $fh_out h1("Summary for G2P complete genes per Individual");

my $maf_key_2_population_name = {
  AFR => '1000GENOMES:phase_3:AFR',
  AMR => '1000GENOMES:phase_3:AMR',
  EAS => '1000GENOMES:phase_3:EAS',
  EUR => '1000GENOMES:phase_3:EUR',
  SAS => '1000GENOMES:phase_3:SAS',
  AA => 'Exome Sequencing Project 6500:African_American',
  EA => 'Exome Sequencing Project 6500:European_American',
  ExAC => 'Exome Aggregation Consortium:Total',
  ExAC_AFR => 'Exome Aggregation Consortium:African/African American',
  ExAC_AMR => 'Exome Aggregation Consortium:American',
  ExAC_Adj => 'Exome Aggregation Consortium:Adjusted',
  ExAC_EAS => 'Exome Aggregation Consortium:East Asian',
  ExAC_FIN => 'Exome Aggregation Consortium:Finnish',
  ExAC_NFE => 'Exome Aggregation Consortium:Non-Finnish European',
  ExAC_OTH => 'Exome Aggregation Consortium:Other',
  ExAC_SAS => 'Exome Aggregation Consortium:South Asian',
};

foreach my $population (@frequencies_header) {
  my $description = $maf_key_2_population_name->{$population};
  print $fh_out p("<b>$population</b> $description");
}

my $switch =<<SHTML;
<form>
<div class="checkbox">
  <label>
    <input class="target" type="checkbox"> Show only canonical transcript
  </label>
</div>
</form>
SHTML

print $fh_out $switch;

foreach my $chart(@charts) {
  print $fh_out hr();
  print $fh_out h3({id => $chart->{id}}, $chart->{title});
  print $fh_out "<TABLE  class=\"table table-bordered\">";
  print $fh_out Tr(th(\@header) );
  foreach my $data (@{$chart->{data}}) {
    my $data_row = $data->[0];
    my $is_canonical = $data->[1];
    my $class = (!$is_canonical) ? 'not_canonical' : 'is_canonical'; 
    print $fh_out Tr( {-class => $class},  td( $data_row ) );
  }
  print $fh_out "</TABLE>\n";
}

print $fh_out '</div>';

print $fh_out hr();

print $fh_out stats_html_tail();

sub stats_html_head {
    my $charts = shift;
    
    my $html =<<SHTML;
<html>
<head>
  <title>VEP summary</title>
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
  <script type="text/javascript" src="http://www.google.com/jsapi"></script>
  <script src="https://code.jquery.com/jquery-1.10.2.js"></script>
</head>
<body>
SHTML
  return $html;
}

sub stats_html_tail {
  my $script =<<SHTML;
  <script>
    \$( "input[type=checkbox]" ).on( "click", function(){
      if (\$('.target').is(':checked')) {
        \$( ".not_canonical" ).hide();
      } else {
        \$( ".not_canonical" ).show();
      }
    } );
  </script>
SHTML
  return "\n</div>\n$script\n</body>\n</html>\n";
}

sub sort_keys {
  my $data = shift;
  my $sort = shift;
  print $data, "\n"; 
  my @keys;
  
  # sort data
  if(defined($sort)) {
    if($sort eq 'chr') {
      @keys = sort {($a !~ /^\d+$/ || $b !~ /^\d+/) ? $a cmp $b : $a <=> $b} keys %{$data};
    }
    elsif($sort eq 'value') {
      @keys = sort {$data->{$a} <=> $data->{$b}} keys %{$data};
    }
    elsif(ref($sort) eq 'HASH') {
      @keys = sort {$sort->{$a} <=> $sort->{$b}} keys %{$data};
    }
  }
  else {
    @keys = keys %{$data};
  }
  
  return \@keys;
}

sub usage {
  print qq{
Usage:
perl write_report.pl --log_dir log_dir
More options
--html_report html_file
--txt_report txt_file
};
}
