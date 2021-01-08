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

use Bio::EnsEMBL::Registry;
use DBI;
use Getopt::Long;
use FileHandle;
use Data::Dumper;
my $config = {};
GetOptions(
  $config,
  'registry_file=s',
  'email=s',
  'import_file=s',
  'panel=s',
) or die "Error: Failed to parse command line arguments\n";
die ('A registry file is required (--registry_file)') unless (defined($config->{registry_file}));

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);

my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');
my $user = $user_adaptor->fetch_by_email($config->{email});
my $panel = $config->{panel};

my $species = 'human';
my $gf_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeature');
my $gfd_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDisease');

my $merge_units = $gfd_adaptor->_get_all_duplicated_LGM_entries_by_panel($panel);
my $count_dup = {};

my $merge_units_dd = $gfd_adaptor->_get_all_duplicated_LGM_entries_by_panel('DD');
my $dont_merge = {};

foreach my $unit (@{$merge_units_dd}) {
  my $allelic_requirement = $unit->{allelic_requirement};
  my $mutation_consequence = $unit->{mutation_consequence};
  $dont_merge->{$allelic_requirement}->{$mutation_consequence} = 1;
}

foreach my $unit (@{$merge_units}) {
  if (!defined $unit->{'allelic_requirement'} || !defined  $unit->{'mutation_consequence'}) {
    print "Missing allelic_requirement and mutation_consequence\n";
    print Dumper $unit;
    next;
  }
  my $ar = $unit->{'allelic_requirement'};
  my $mc = $unit->{'mutation_consequence'};

  next if (defined $dont_merge->{$ar}->{$mc});

  # if entry is also in DD panel use disease name that is used in DD panel as the main one. Other disease names will be used as disease
  # name synonyms   
  my $disease_name_from_DD_panel = get_disease_name_from_DD_panel($unit);
  my @gfd_ids = ();
  my $lgms = get_all_lgms($unit, $panel);

  if (scalar @$lgms == 0) {
    print "Missing lgms\n";
    print Dumper $unit;
    next;
  }

  my ($gf_id, $disease_id, $target_lgm);
  if (defined $disease_name_from_DD_panel) {
    ($target_lgm) = grep {$_->{disease_name} eq $disease_name_from_DD_panel} @$lgms;
    if (!defined $target_lgm) {
      $target_lgm = $lgms->[0];
    }
  } else {
    $target_lgm = $lgms->[0];
  }
  $gf_id =  $target_lgm->{gf_id};
  $disease_id = $target_lgm->{disease_id};
  foreach my $lgm (@$lgms) {
    push @gfd_ids, $lgm->{gfd_id};
  }

  if (!defined $disease_id) {
    print "Missing disease_id\n";
    print Dumper $unit;
  } else {
    my $gfd = $gfd_adaptor->_merge_all_duplicated_LGM_by_panel_gene($user, $gf_id, $disease_id, $panel, \@gfd_ids);
  }
}
#unit:
#{
#'count' => 2,
#'allelic_requirement_attrib' => '14',
#'panel' => 'Skin',
#'mutation_consequence_attrib' => '24',
#'panel_id' => 41,
#'genomic_feature_id' => 36442,
#'mutation_consequence' => 'dominant negative',
#'allelic_requirement' => 'monoallelic',
#'gene_symbol' => 'PPARG',
#'gf_id' => 36442
#};

# get all entries from a specific panel with the same locus, genotype and mechanism
sub get_all_lgms {
  my $unit = shift;
  my $panel = shift;
  my $gf_id = $unit->{gf_id};
  my $allelic_requirement_attrib = $unit->{allelic_requirement_attrib};
  my $mutation_consequence_attrib = $unit->{mutation_consequence_attrib};

  my $genomic_feature = $gf_adaptor->fetch_by_dbID($gf_id);
  my $gfds = $gfd_adaptor->fetch_all_by_GenomicFeature_panel($genomic_feature, $panel);

  my @entries = ();
  foreach my $gfd (@$gfds) {
    my $gfd_actions = $gfd->get_all_GenomicFeatureDiseaseActions;
    next if (scalar @$gfd_actions != 1);
    my $is_lgm_match = 0;
    foreach my $action (@$gfd_actions) {
      next if (!$action->allelic_requirement_attrib || !$action->mutation_consequence_attrib);
      if ($action->allelic_requirement_attrib == $allelic_requirement_attrib && $action->mutation_consequence_attrib == $mutation_consequence_attrib) {
        $is_lgm_match = 1;
      }
    }
    next if (!$is_lgm_match);
    my $gf_id = $gfd->get_GenomicFeature->dbID;
    my $disease_id = $gfd->get_Disease->dbID;
    my $disease_name = $gfd->get_Disease->name;
    my $gfd_id = $gfd->dbID;

    push @entries, {
      disease_id => $disease_id,
      disease_name => $disease_name,
      gf_id => $gf_id,
      gfd_id => $gfd_id,
    };
  }
  return \@entries;
}

sub get_disease_name_from_DD_panel {
  my $unit = shift;
  my $gf_id = $unit->{gf_id};
  my $allelic_requirement_attrib = $unit->{allelic_requirement_attrib};
  my $mutation_consequence_attrib = $unit->{mutation_consequence_attrib};
  my $genomic_feature = $gf_adaptor->fetch_by_dbID($gf_id);
  my $gfds = $gfd_adaptor->fetch_all_by_GenomicFeature_panel($genomic_feature, 'DD');
  foreach my $gfd (@$gfds) {
    my $gfd_actions = $gfd->get_all_GenomicFeatureDiseaseActions;
    next if (scalar @$gfd_actions != 1);
    if (grep {$_->allelic_requirement_attrib == $allelic_requirement_attrib && $_->mutation_consequence_attrib == $mutation_consequence_attrib} @$gfd_actions) {
      return $gfd->get_Disease->name;
    }
  }
  return undef;
}


