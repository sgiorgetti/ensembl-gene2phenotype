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
) or die "Error: Failed to parse command line arguments\n";
die ('A registry file is required (--registry_file)') unless (defined($config->{registry_file}));

my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);

my $species = 'human';
my $gf_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeature');
my $gfd_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GenomicFeatureDisease');
my $dbh = $registry->get_DBAdaptor($species, 'gene2phenotype')->dbc->db_handle;

my @panels = qw/Eye Skin DD Cancer/;

foreach my $panel (@panels) {
  update_restricted_mutation_set_flag($panel);
}

sub update_restricted_mutation_set_flag {
  my $panel = shift;
  my $merge_units = $gfd_adaptor->_get_all_duplicated_LGM_entries_by_panel($panel);
  foreach my $unit (@{$merge_units}) {
    if (!defined $unit->{'allelic_requirement'} || !defined  $unit->{'mutation_consequence'}) {
      print "Missing allelic_requirement and mutation_consequence\n";
      print Dumper $unit;
      next;
    }
    my $ar = $unit->{'allelic_requirement'};
    my $mc = $unit->{'mutation_consequence'};
    print "allelic_requirement $ar mutation_consequence $mc\n";

    my $lgms = get_all_lgms($unit, $panel);

    if (scalar @$lgms == 0) {
      print "Missing lgms\n";
      print Dumper $unit;
      next;
    }
    foreach my $lgm (@{$lgms}) {
      my $gfd_id = $lgm->{gfd_id};
      $dbh->do(qq{UPDATE genomic_feature_disease SET restricted_mutation_set=1 WHERE genomic_feature_disease_id=$gfd_id;}) or die $dbh->errstr;
    }
  }
}

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


