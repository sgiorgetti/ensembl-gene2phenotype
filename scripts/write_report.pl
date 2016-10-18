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
use CGI qw/:standard/;


my $args = scalar @ARGV;
my $config = {};
GetOptions(
    $config,
    'help|h',            # displays help message
    'report_file=s',
) or die "ERROR: Failed to parse command-line flags\n";

if (defined($config->{help}) || !$args ) {
  &usage;
  exit(0);
}

my $report_file = $config->{report_file};

die "ERROR: File doesn't exist." if (!-f $report_file);


my @frequencies_header = qw/AFR AMR EAS EUR SAS AA EA ExAC ExAC_AFR ExAC_AMR ExAC_Adj ExAC_EAS ExAC_FIN ExAC_NFE ExAC_OTH ExAC_SAS/;


my $html_output_file = "$report_file.html";

my $fh = FileHandle->new($report_file, 'r');

my $genes = {};
my $individuals = {};
my $complete_genes = {};
my $g2p_list = {};
my $in_vcf_file = {};

while (<$fh>) {
  chomp;
  if (/^G2P_list/) {
    my ($flag, $gene_symbol, $DDD_category) = split/\t/;
    $g2p_list->{$gene_symbol} = 1;
  } elsif (/^G2P_in_vcf/) {
    my ($flag, $gene_symbol) = split/\t/;
    $in_vcf_file->{$gene_symbol} = 1;
  } elsif (/^G2P_complete/) {
    my ($flag, $gene_symbol, $individual) = split/\t/;
    $complete_genes->{$gene_symbol}->{$individual} = 1;
  } elsif (/^G2P_flag/) {
    my ($flag, $gene_symbol, $tr_stable_id, $individual, $vf_name, $g2p_data) = split/\t/;
    $genes->{$gene_symbol}->{"$individual\t$vf_name"}->{$tr_stable_id} = $g2p_data;
    $individuals->{$individual}->{$gene_symbol}->{$vf_name}->{$tr_stable_id} = $g2p_data;
  } else {

  }
}
$fh->close();

my $count_g2p_genes = keys %$g2p_list;
my $count_in_vcf_file = keys %$in_vcf_file;
my $count_complete_genes = keys %$complete_genes;

my $chart_data = {};

foreach my $individual (keys %$individuals) {
  foreach my $gene_symbol (keys %{$individuals->{$individual}}) {
    if ($complete_genes->{$gene_symbol}->{$individual}) {
      foreach my $vf_name (keys %{$individuals->{$individual}->{$gene_symbol}}) {
        foreach my $tr_stable_id (keys %{$individuals->{$individual}->{$gene_symbol}->{$vf_name}}) {
          my $data = $individuals->{$individual}->{$gene_symbol}->{$vf_name}->{$tr_stable_id};
          my $hash = {};
          foreach my $pair (split/;/, $data) {
            my ($key, $value) = split('=', $pair, 2);
            $value ||= '';
            $hash->{$key} = $value;
          }
          my $refseq = $hash->{refseq};
          my $failed = $hash->{failed};
          my $clin_sign = $hash->{clin_sig};
          my $novel = $hash->{novel};
          my $hgvs_t = $hash->{hgvs_t};
          my $hgvs_p = $hash->{hgvs_p}; 
          my $allelic_requirement = $hash->{allele_requirement};
          my $consequence_types = $hash->{consequence_types};
          my $zygosity = $hash->{zyg};
          my %frequencies_hash = ();
          if ($hash->{frequencies} ne 'NA') {
            %frequencies_hash = split /[,=]/, $hash->{frequencies};
          }
          my @frequencies = ();
          foreach my $population (@frequencies_header) {
            my $frequency = $frequencies_hash{$population};
            push @frequencies, "'$frequency'";
          }         
          my $frequencies = join(', ', @frequencies);
          push @{$chart_data->{$individual}}, "['$gene_symbol', '$tr_stable_id', '$hgvs_t', '$hgvs_p', '$refseq', '$vf_name', '$novel', '$failed', '$clin_sign', '$consequence_types', '$allelic_requirement', '$zygosity', $frequencies]";
        } 
      }    
    }
  }
}

my @charts = ();
my $count = 1;
foreach my $individual (sort keys %$chart_data) {
  my $header = "['Gene symbol','Transcript stable ID', 'HGVS transcript', 'HGVS protein', 'RefSeq IDs', 'Variant name', 'Novel variant', 'Has been failed by Ensembl', 'ClinVar annotation', 'Consequence types', 'Allelic requirement', 'Zygosity'," . join(', ', map {"'$_'"} @frequencies_header) . " ]";
  push @charts, {
    type => 'Table',
    id => "ind_$count",
    title => $individual,
    header => $header,
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

# genes not found in input VCF file
foreach my $chart(@charts) {
  print $fh_out hr();
  print $fh_out h3({id => $chart->{id}}, $chart->{title});
  print $fh_out div({id => $chart->{id}."_".$chart->{type}, style => 'width: 100%'}, '&nbsp;');
}

print $fh_out '</div>';


print $fh_out stats_html_tail();

sub stats_html_head {
    my $charts = shift;
    
    my ($js);
    foreach my $chart(@$charts) {
#      my @keys = @{sort_keys($chart->{data}, $chart->{sort})};
      
      my $type = ucfirst($chart->{type});
      
      
      # code to draw chart
      $js .= sprintf(
        "var %s = draw$type('%s', '%s', google.visualization.arrayToDataTable([%s,%s]), %s);\n",
        $chart->{id}.'_'.$chart->{type},
        $chart->{id}.'_'.$chart->{type},
        $chart->{title},
        $chart->{header},
        join(",", @{$chart->{data}}),
        $chart->{options} || 'null',
      );
      
    }
    
    my $html =<<SHTML;
<html>
<head>
  <title>VEP summary</title>
  <script type="text/javascript" src="http://www.google.com/jsapi"></script>
  <script type="text/javascript">
    google.load('visualization', '1', {packages: ['corechart','table']});
  </script>
  <script type="text/javascript">
    
    function init() {
      // charts
      $js
    }
    
    function drawPie(id, title, data, options) {    
      var pie = new google.visualization.PieChart(document.getElementById(id));
      pie.draw(data, options);
      return pie;
    }
    function drawBar(id, title, data, options) {
      var bar = new google.visualization.ColumnChart(document.getElementById(id));
      bar.draw(data, options);
      return bar;
    }
    function drawTable(id, title, data) {
      var table = new google.visualization.Table(document.getElementById(id));
      table.draw(data, null);
      return table;
    }
    function drawLine(id, title, data, options) {
      var line = new google.visualization.LineChart(document.getElementById(id));
      line.draw(data, options);
      return line;
    }
    function drawArea(id, title, data, options) {
      var area = new google.visualization.AreaChart(document.getElementById(id));
      area.draw(data, options);
      return area;
    }
    google.setOnLoadCallback(init);
  </script>
  
  
  <style type="text/css">
    body {
      font-family: arial, sans-serif;
      margin: 0px;
      padding: 0px;
    }
    
    a {color: #36b;}
    a.visited {color: #006;}
    
    .stats_table {
      margin: 5px;
    }
    
    tr:nth-child(odd) {
      background-color: rgb(238, 238, 238);
    }
    
    th {
      text-align: left;
    }   
 
    td {
      padding: 5px;
    }
    
    td:nth-child(odd) {
      font-weight: bold;
    }
    
    h3 {
      color: #666;
    }
    
    .masthead {
      background-color: rgb(51, 51, 102);
      color: rgb(204, 221, 255);
      height: 80px;
      width: 100%;
      padding: 0px;
    }
    
    .main {
      padding: 10px;
    }
    
    .gradient {
      background: #333366; /* Old browsers */
      background: -moz-linear-gradient(left,  #333366 0%, #ffffff 100%); /* FF3.6+ */
      background: -webkit-gradient(linear, left top, right top, color-stop(0%,#333366), color-stop(100%,#ffffff)); /* Chrome,Safari4+ */
      background: -webkit-linear-gradient(left,  #333366 0%,#ffffff 100%); /* Chrome10+,Safari5.1+ */
      background: -o-linear-gradient(left,  #333366 0%,#ffffff 100%); /* Opera 11.10+ */
      background: -ms-linear-gradient(left,  #333366 0%,#ffffff 100%); /* IE10+ */
      background: linear-gradient(to right,  #333366 0%,#ffffff 100%); /* W3C */
      filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#333366', endColorstr='#ffffff',GradientType=1 ); /* IE6-9 */
      
      padding: 0px;
      height: 80px;
      width: 500px;
    }
    
    .main_content {
    }
    
    .sidemenu {
      width: 260px;
      position: fixed;
      border-style: solid;
      border-width: 2px;
      border-color: rgb(51, 51, 102);
    }
    
    .sidemenu_head {
      width: 250px;
      background-color: rgb(51, 51, 102);
      color: rgb(204, 221, 255);
      padding: 5px;
    }
    
    .sidemenu_body {
      width: 250px;
      padding: 5px;
    }
  </style>
</head>
<body>
<div class="main">
SHTML

    return $html;
}

sub stats_html_tail {
  return "\n</div></body>\n</html>\n";
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
perl write_report.pl report_file
report_file: The file generated by the G2P plugin
};
}
