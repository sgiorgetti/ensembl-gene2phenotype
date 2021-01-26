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

use Data::Dumper;
use FileHandle;
use Getopt::Long;
use Bio::EnsEMBL::Registry;
my $config = {};

GetOptions(
  $config,
  'registry_file=s',
  'output_file=s',
  'mode=s',
) or die "Error: Failed to parse command line arguments\n";

die ('A registry_file file is required (--registry_file)') unless (defined($config->{registry_file}));

my $species = 'Homo_sapiens';

my $registry = 'Bio::EnsEMBL::Registry';

my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);
my $LGM_panel_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'LGMPanel');
my $panel_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'panel');
my $gfda = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');

if ($config->{mode} eq 'print_duplicated_lgms') {
  print_duplicated_lgms();
} else {
  print_unique_lgms();
}
sub print_duplicated_lgms {
  my $panels = $panel_adaptor->fetch_all(); 
  my $panel_2_lgm = {};
  my $lgm_ids = {};
  my $lgm_counts = 0;
  foreach my $panel (@$panels) {
    my $panel_name = $panel->name;
    next if ($panel_name eq 'Demo');
    my $merge_list = $gfda->_get_all_duplicated_LGM_entries_by_panel($panel_name);
    foreach my $list (@{$merge_list}) {
      my $gene_symbol = $list->{gene_symbol};
      my $genotype = $list->{allelic_requirement};
      my $mechanism = $list->{mutation_consequence};
      next if (! $genotype || ! $mechanism);
      my $lgm_id = "$gene_symbol $genotype $mechanism";
      if (!defined $lgm_ids->{$lgm_id}) {
        $lgm_counts++;
        $lgm_ids->{$lgm_id} = $lgm_counts;
      }
      $panel_2_lgm->{$panel_name}->{$lgm_id} = 1;
    }
  }
  my $output_file = $config->{output_file}; 
  my $fh = FileHandle->new($output_file, 'w');
  my @sorted_panel_names = sort keys %$panel_2_lgm;
  print $fh join(";", 'lgm_id', @sorted_panel_names), "\n";

  foreach my $lgm_id (keys %$lgm_ids) {
    my @is_in_panel = ();
    foreach my $panel (@sorted_panel_names) {
      if (defined $panel_2_lgm->{$panel}->{$lgm_id}) {
        push @is_in_panel, 1;
      } else {
        push @is_in_panel, 0;
      }
    }
    print $fh join(";", $lgm_ids->{$lgm_id}, @is_in_panel), "\n";
  }
  $fh->close();
}

sub print_unique_lgms {
  my $lgm_panels = $LGM_panel_adaptor->fetch_all();
  my $panel_2_lgm = {};
  my $lgm_ids = {};
  my $panels = {};
  foreach my $lgm_panel (@$lgm_panels) {
    my $lgm = $lgm_panel->get_LocusGenotypeMechanism;
    next if ($lgm->locus_type ne 'gene');
    my $panel = $lgm_panel->get_Panel;
    my $panel_name = $panel->name;
    $panel_2_lgm->{$panel_name}->{$lgm->dbID} = 1;
    $lgm_ids->{$lgm->dbID} = 1;
    $panels->{$panel_name} = 1;
  }

  my $output_file = $config->{output_file}; 
  my $fh = FileHandle->new($output_file, 'w');

  my @sorted_panel_names = sort keys %$panel_2_lgm;
  print $fh join(";", 'lgm_id', @sorted_panel_names), "\n";

  foreach my $lgm_id (keys %$lgm_ids) {
    my @is_in_panel = ();
    foreach my $panel (@sorted_panel_names) {
      if (defined $panel_2_lgm->{$panel}->{$lgm_id}) {
        push @is_in_panel, 1;
      } else {
        push @is_in_panel, 0;
      }
    }
    print $fh join(";", $lgm_id, @is_in_panel), "\n";
  }

  $fh->close();
}

