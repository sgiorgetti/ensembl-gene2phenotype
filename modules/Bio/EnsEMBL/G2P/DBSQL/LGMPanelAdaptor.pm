=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2020] EMBL-European Bioinformatics Institute
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
     http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=cut
use strict;
use warnings;

package Bio::EnsEMBL::G2P::DBSQL::LGMPanelAdaptor;

use DBI qw(:sql_types);
use Bio::EnsEMBL::G2P::LGMPanel;

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $lgm_panel = shift;

  if (!ref($lgm_panel) || !$lgm_panel->isa('Bio::EnsEMBL::G2P::LGMPanel')) {
    die('Bio::EnsEMBL::G2P::LGMPanel arg expected');
  }

  my $attribute_adaptor = $self->db->get_AttributeAdaptor;
  if ( defined $lgm_panel->{confidence_category} ) {
    $lgm_panel->{confidence_category_attrib} = $attribute_adaptor->attrib_id_for_type_value('confidence_category', $lgm_panel->{confidence_category});
    if (!defined $lgm_panel->{confidence_category_attrib}) {
      die "Could not get attrib value for confidence_category " . $lgm_panel->{confidence_category_attrib};
    }
  }

  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO LGM_panel(
      locus_genotype_mechanism_id,
      panel_id,
      confidence_category_attrib,
      user_id,
      created
    ) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
  });

  $sth->execute(
    $lgm_panel->locus_genotype_mechanism_id,
    $lgm_panel->panel_id,
    $lgm_panel->{confidence_category_attrib},
    $lgm_panel->user_id
  );

  $sth->finish();
  
  my $dbID = $dbh->last_insert_id(undef, undef, 'LGM_panel', 'LGM_panel_id'); 
  $lgm_panel->{dbID} = $dbID;

  return $lgm_panel;
}

sub fetch_all {
  my $self = shift;
  return $self->generic_fetch();
}

sub fetch_all_by_LocusGenotypeMechanism {
  my $self = shift;
  my $locus_genotype_mechanism = shift;
  my $locus_genotype_mechanism_id = $locus_genotype_mechanism->dbID;
  my $constraint = "locus_genotype_mechanism_id=$locus_genotype_mechanism_id;";
  return $self->generic_fetch($constraint);
}

sub fetch_by_LocusGenotypeMechanism_Panel {
  my $self = shift;
  my $locus_genotype_mechanism = shift;
  my $panel = shift;
  my $locus_genotype_mechanism_id = $locus_genotype_mechanism->dbID;
  my $panel_id = $panel->dbID;
  my $constraint = "locus_genotype_mechanism_id=$locus_genotype_mechanism_id AND panel_id=$panel_id;";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub _columns {
  my $self = shift;
  my @cols = (
    'LGM_panel_id',
    'locus_genotype_mechanism_id',
    'panel_id',
    'confidence_category_attrib',
    'user_id',
    'created',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['LGM_panel'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;
  my ($LGM_panel_id, $locus_genotype_mechanism_id, $panel_id, $confidence_category_attrib, $user_id, $created);
  $sth->bind_columns(\($LGM_panel_id, $locus_genotype_mechanism_id, $panel_id, $confidence_category_attrib, $user_id, $created));

  my @objs;

  my $attribute_adaptor = $self->db->get_AttributeAdaptor;

  while ($sth->fetch()) {
    my $confidence_category = undef;
    if ($confidence_category_attrib) {
      $confidence_category = $attribute_adaptor->attrib_value_for_id($confidence_category_attrib);
    }
    my $obj = Bio::EnsEMBL::G2P::LGMPanel->new(
      -LGM_panel_id => $LGM_panel_id,
      -locus_genotype_mechanism_id => $locus_genotype_mechanism_id,
      -panel_id => $panel_id,
      -confidence_category_attrib => $confidence_category_attrib,
      -confidence_category => $confidence_category,
      -user_id => $user_id,
      -created => $created,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
