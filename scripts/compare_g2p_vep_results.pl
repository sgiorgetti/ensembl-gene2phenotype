# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
use strict;
use warnings;

use FileHandle;
use Getopt::Long;

my $args = scalar @ARGV;
my $config = {};
GetOptions(
  $config,
  'file1=s',
  'file2=s',
  'help|h',
) or die "Error: Failed to parse command line arguments\n";
die ('file1 is required (--file1)') unless (defined($config->{file1}));
die ('file2 is required (--file2)') unless (defined($config->{file2}));
if (defined($config->{help}) || !$args ) {
  &usage;
  exit(0);
}

my $sets = {};

read_file($config->{file1});
read_file($config->{file2});

compare_sets($config->{file1}, $config->{file2});
compare_sets($config->{file2}, $config->{file1});

sub read_file {
  my $file = shift;
  my $fh = FileHandle->new($file, 'r');
  while (<$fh>) {
    chomp;
    my ($individual, $gene_symbol, $transcript_id, $is_canonical, $obs, $req, $attribs) = split/\t/;
    $sets->{$file}->{$individual}->{$gene_symbol}->{$transcript_id}->{is_canonical}->{$is_canonical} = 1;
    $sets->{$file}->{$individual}->{$gene_symbol}->{$transcript_id}->{obs}->{$obs} = 1;
    $sets->{$file}->{$individual}->{$gene_symbol}->{$transcript_id}->{req}->{$req} = 1;

    my @variants = split(';', $attribs);
    foreach my $variant (@variants) {
      my ($chr, $start, $end, $ref, $alt, $zygosity, $consequence, $sift, $polyphen, $frequencies) = split(':', $variant);
      my $variant_key = "$chr-$start-$end-$ref-$alt";
      $sets->{$file}->{$individual}->{$gene_symbol}->{$transcript_id}->{variants}->{$variant_key} = 1;
    }
  }
  $fh->close();
}

sub compare_sets {
  my $file1 = shift;
  my $file2 = shift;
  my $set1 = $sets->{$file1};
  my $set2 = $sets->{$file2};
  foreach my $individual (keys %$set1) {
    if (!$set2->{$individual}) {
      warn "Individual $individual is missing from $file2\n"; 
      next;
    } 
    foreach my $gene_symbol (keys %{$set1->{$individual}}) { 
      if (!$set2->{$individual}->{$gene_symbol}) {
        warn "Individual $individual is missing gene $gene_symbol in $file2\n";    
        next;
      }
      foreach my $transcript_id (keys %{$set1->{$individual}->{$gene_symbol}}) {
        if (!$set2->{$individual}->{$gene_symbol}->{$transcript_id}) {
          warn "Gene $gene_symbol in individual $individual is missing transcript $transcript_id in file $file2\n";
          next;
        } 

        my $transcript1 = $set1->{$individual}->{$gene_symbol}->{$transcript_id};
        my $transcript2 = $set2->{$individual}->{$gene_symbol}->{$transcript_id};
        foreach my $key (qw/is_canonical obs req variants/) {
          my @array1 = keys $transcript1->{$key};
          my @array2 = keys $transcript2->{$key};
          if (!compare_arrays(\@array1, \@array2)) {
            warn "Different content in arrays for $key ($individual > $gene_symbol > $transcript_id): $file1 = ", join(', ', @array1), ' ', $file2, " = ", join(', ', @array2), "\n";
          } 
        }        
      }
    }
  } 
}

sub compare_arrays {
  my $array1 = shift;
  my $array2 = shift;
  return (scalar @$array1 == scalar @$array2);
  foreach my $i (@$array1) {
    if (! (grep($i, @$array2)) ) {
      return 0;
    }
  }
  return 1;
}

sub usage {
  print qq{
Usage:
perl compare_g2p_vep_results.pl --file1 file1 --file2 file2
};
}
