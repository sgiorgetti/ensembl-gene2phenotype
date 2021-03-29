=head1 LICENSE
 
See the NOTICE file distributed with this work for additional information
regarding copyright ownership.
 
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

package Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseasePanelAdaptor;

use Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $gfd_panel = shift;
  my $user = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($gfd_panel) || !$gfd_panel->isa('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel')) {
    die('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel arg expected');
  }

  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die('Bio::EnsEMBL::G2P::User arg expected');
  }

  if (! (defined $gfd_panel->{panel} || defined $gfd_panel->{panel_attrib})) {
    die "panel or panel_attrib is required\n";
  }

  if (! (defined $gfd_panel->{confidence_category} || defined $gfd_panel->{confidence_category_attrib})) {
    die "confidence_category or confidence_category_attrib is required\n";
  }

  my $aa = $self->db->get_AttributeAdaptor;
  if ( defined $gfd_panel->{panel} ) {
    my $panel_attrib = $aa->attrib_id_for_type_value('g2p_panel', $gfd_panel->{panel});
    die "Could not get panel attrib id for value ", $gfd_panel->{panel}, "\n" unless ($panel_attrib);
    $gfd_panel->{panel_attrib} = $panel_attrib;
  }

  if ( defined $gfd_panel->{confidence_category} ) {
    my $confidence_category_attrib = $aa->attrib_id_for_type_value('confidence_category', $gfd_panel->{confidence_category});
    die "Could not get confidence category attrib id for value ", $gfd_panel->{confidence_category}, "\n" unless ($confidence_category_attrib);
    $gfd_panel->{confidence_category_attrib} = $confidence_category_attrib;
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_panel(
      genomic_feature_disease_id,
      confidence_category_attrib,
      is_visible,
      panel_attrib
    ) VALUES (?, ?, ?, ?)
  });

  $sth->execute(
    $gfd_panel->{genomic_feature_disease_id},
    $gfd_panel->{confidence_category_attrib},
    $gfd_panel->is_visible || 1,
    $gfd_panel->{panel_attrib}
  );

  $sth->finish();
  
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease_panel', 'genomic_feature_disease_panel_id'); 
  $gfd_panel->{genomic_feature_disease_panel_id} = $dbID;

  $self->update_log($gfd_panel, $user, 'create');

  return $gfd_panel;
}

sub delete {
  my $self = shift;
  my $gfd_panel = shift;
  my $user = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($gfd_panel) || !$gfd_panel->isa('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel')) {
    die ('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel arg expected');
  }

  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die ('Bio::EnsEMBL::G2P::User arg expected');
  }

  my $gfd_panel_id = $gfd_panel->dbID; 

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_panel_deleted (
      genomic_feature_disease_panel_id,
      genomic_feature_disease_id,
      confidence_category_attrib,
      is_visible,
      panel_attrib,
      deleted,
      deleted_by_user_id
    ) VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?)
  });

  $sth->execute(
    $gfd_panel->dbID,
    $gfd_panel->genomic_feature_disease_id,
    $gfd_panel->confidence_category_attrib,
    $gfd_panel->is_visible,
    $gfd_panel->panel_attrib,
    $user->user_id
  );
  $sth->finish();

  $sth = $dbh->prepare(q{
    DELETE FROM genomic_feature_disease_panel WHERE genomic_feature_disease_panel_id = ?;
  });

  $sth->execute($gfd_panel->dbID);
  $sth->finish();
}

sub update {
  my $self = shift;
  my $gfd_panel = shift;
  my $user = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($gfd_panel) || !$gfd_panel->isa('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel')) {
    die('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel arg expected');
  }

  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die('Bio::EnsEMBL::G2P::User arg expected');
  }

  my $sth = $dbh->prepare(q{
    UPDATE genomic_feature_disease_panel
    SET
      confidence_category_attrib = ?,
      is_visible = ?,
      panel_attrib = ?,
      restricted_mutation_set = ?
    WHERE genomic_feature_disease_panel_id = ? 
  });
  $sth->execute(
    $gfd_panel->confidence_category_attrib,
    $gfd_panel->is_visible,
    $gfd_panel->panel_attrib,
    $gfd_panel->restricted_mutation_set,
    $gfd_panel->dbID
  );
  $sth->finish();

  $self->update_log($gfd_panel, $user, 'update');

  return $gfd_panel;
}

sub update_log {
  my $self = shift;
  my $gfd_panel = shift;
  my $user = shift;
  my $action = shift;

  my $gfd_panel_log_adaptor = $self->db->get_GFPPanelLogAdaptor;
  my $gfd_panel_log = Bio::EnsEMBL::G2P::GFDPanelLog->new(
    -genomic_feature_disease_panel_id => $gfd_panel->dbID,
    -genomic_feature_disease_id => $gfd_panel->genomic_feature_disease_id,
    -confidence_category_attrib => $gfd_panel->confidence_category_attrib,
    -user_id => $user->dbID,
    -action => $action, 
    -adaptor => $GFD_panel_log_adaptor,
  );
  $gfd_panel_log_adaptor->store($gfd_panel_log);
}

sub fetch_by_dbID {
  my $self = shift;
  my $genomic_feature_disease_panel_id = shift;
  return $self->SUPER::fetch_by_dbID($genomic_feature_disease_panel_id);
}

sub fetch_all_by_GenomicFeatureDisease {
  my $self = shift;
  my $genomic_feature_disease = shift;
  my $gfd_id = $genomic_feature_disease->dbID;
  my $constraint = "gfd_panel.genomic_feature_disease_id=$gfd_id;";
  return $self->generic_fetch($constraint);
}

sub fetch_by_GenomicFeatureDisease_panel {
  my $self = shift;
}

sub fetch_all_by_GenomicFeature_panel {
  my $self = shift;
  my $genomic_feature = shift;
  my $panel = shift;

  if ($panel eq 'ALL') {
    return $self->fetch_all_by_GenomicFeature($genomic_feature);
  }
  my $attribute_adaptor = $self->db->get_AttributeAdaptor;
  my $panel_id = $attribute_adaptor->attrib_id_for_value($panel);

  my $genomic_feature_id = $genomic_feature->dbID;
  my $constraint = "gfd_panel.genomic_feature_id=$genomic_feature_id AND gfd_panel.panel_attrib=$panel_id";
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_GenomicFeature_panels {
  my $self = shift;
  my $genomic_feature = shift;
  my $panels = shift;

  my $attribute_adaptor = $self->db->get_AttributeAdaptor;
  my @panel_ids = ();
  foreach my $panel (@$panels) {
    my $panel_id = $attribute_adaptor->attrib_id_for_value($panel);
    push @panel_ids, $panel_id;
  } 
  my $genomic_feature_id = $genomic_feature->dbID;
  my $constraint = "gfd_panel.genomic_feature_id=$genomic_feature_id AND gfd_panel.panel_attrib IN (" . join(',', @panel_ids) . ")";
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_Disease {
  my $self = shift;
  my $disease = shift;
  my $disease_id = $disease->dbID;
  my $constraint = "gfd_panel.disease_id=$disease_id";
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_Disease_panel {
  my $self = shift;
  my $disease = shift;
  my $panel = shift;
  if ($panel eq 'ALL') {
    return $self->fetch_all_by_Disease($disease);
  } 
  my $attribute_adaptor = $self->db->get_AttributeAdaptor;
  my $panel_id = $attribute_adaptor->attrib_id_for_value($panel);

  my $disease_id = $disease->dbID;
  my $constraint = "gfd_panel.disease_id=$disease_id AND gfd_panel.panel_attrib=$panel_id";
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_Disease_panels {
  my $self = shift;
  my $disease = shift;
  my $panels = shift;

  my $attribute_adaptor = $self->db->get_AttributeAdaptor;
  my @panel_ids = ();
  foreach my $panel (@$panels) {
    my $panel_id = $attribute_adaptor->attrib_id_for_value($panel);
    push @panel_ids, $panel_id;
  } 

  my $disease_id = $disease->dbID;
  my $constraint = "gfd_panel.disease_id=$disease_id AND gfd_panel.panel_attrib IN (" . join(',', @panel_ids) . ")";
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_disease_id {
  my $self = shift;
  my $disease_id = shift;
  my $constraint = qq{gfd_panel.disease_id = ?};
  $self->bind_param_generic_fetch($disease_id, SQL_INTEGER);
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_panel {
  my $self = shift;
  my $panel = shift;
  if ($panel eq 'ALL') {
    return $self->fetch_all();
  } 
  my $attribute_adaptor = $self->db->get_AttributeAdaptor;
  my $panel_id = $attribute_adaptor->attrib_id_for_value($panel);
  my $constraint = "gfd_panel.panel_attrib=$panel_id";
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_panel_restricted {
  my $self = shift;
  my $panel = shift;
  if ($panel eq 'ALL') {
    return $self->fetch_all();
  } 
  my $attribute_adaptor = $self->db->get_AttributeAdaptor;
  my $panel_id = $attribute_adaptor->attrib_id_for_value($panel);
  my $constraint = "gfd_panel.panel_attrib=$panel_id AND gfd_panel.is_visible = 0";
  return $self->generic_fetch($constraint);
}

sub get_statistics {
  my $self = shift;
  my $panels = shift;
  my $attribute_adaptor = $self->db->get_AttributeAdaptor;
  my $confidence_categories = $attribute_adaptor->get_attribs_by_type_value('confidence_category');
  %$confidence_categories = reverse %$confidence_categories;
  my $panel_attrib_ids = join(',', @$panels);
  my $sth = $self->prepare(qq{
    select a.value, gfd_panel.confidence_category_attrib, count(*)
    from genomic_feature_disease gfd_panel, attrib a
    where a.attrib_id = gfd_panel.panel_attrib
    AND gfd_panel.panel_attrib IN ($panel_attrib_ids)
    group by a.value, gfd_panel.confidence_category_attrib;
  });
  $sth->execute;

  my $hash = {};
  while (my ($panel, $confidence_category_attrib_id, $count) = $sth->fetchrow_array) {
    my $confidence_category_value = $confidence_categories->{$confidence_category_attrib_id};
    $hash->{$panel}->{$confidence_category_value} = $count;
  }
  my @results = ();
  my @header = ('Panel', 'confirmed', 'probable', 'possible', 'both RD and IF', 'child IF'); 
  push @results, \@header;
  foreach my $panel (sort keys %$hash) {
    my @row = ();
    push @row, $panel;
    for (my $i = 1; $i <= $#header; $i++) {
      push @row, ($hash->{$panel}->{$header[$i]} || 0) + 0;
    }
    push @results, \@row;
  }

  return \@results;
}

sub fetch_all_by_panel_without_publications {
  my $self = shift;
  my $panel = shift;
  my $constraint = '';
  if ($panel ne 'ALL') {
    my $attribute_adaptor = $self->db->get_AttributeAdaptor;
    my $panel_id = $attribute_adaptor->attrib_id_for_value($panel);
    $constraint = "AND gfd_panel.panel_attrib=$panel_id";
  } 
  my $cols = join ",", $self->_columns();
  my $sth = $self->prepare(qq{
    SELECT $cols FROM genomic_feature_disease gfd_panel
    LEFT JOIN genomic_feature_disease_publication gfd_panelp
    ON gfd_panel.genomic_feature_disease_id = gfd_panelp.genomic_feature_disease_id
    WHERE gfd_panelp.genomic_feature_disease_id IS NULL
    $constraint;
  });

  $sth->execute;
  return $self->_objs_from_sth($sth);
}

sub fetch_all {
  my $self = shift;
  return $self->generic_fetch();
}

sub _columns {
  my $self = shift;
  my @cols = (
    'gfd_panel.genomic_feature_disease_panel_id',
    'gfd_panel.genomic_feature_disease_id',
    'gfd_panel.confidence_category_attrib',
    'gfd_panel.is_visible',
    'gfd_panel.panel_attrib',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['genomic_feature_disease_panel', 'gfd_panel'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my (
    $genomic_feature_disease_panel_id,
    $genomic_feature_disease_id,
    $confidence_category_attrib,
    $is_visible,
    $panel_attrib,
    $restricted_mutation_set
  );
  $sth->bind_columns(\(
    $genomic_feature_disease_panel_id,
    $genomic_feature_disease_id,
    $confidence_category_attrib,
    $is_visible,
    $panel_attrib,
    $restricted_mutation_set
  ));

  my @objs;

  my $attribute_adaptor = $self->db->get_AttributeAdaptor;

  while ($sth->fetch()) {
    my $confidence_category = undef; 
    my $panel = undef; 
    if ($confidence_category_attrib) {
      $confidence_category = $attribute_adaptor->attrib_value_for_id($confidence_category_attrib);
    }
    if ($panel_attrib) {
      $panel = $attribute_adaptor->attrib_value_for_id($panel_attrib);
    }

    my $obj = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePanel->new(
      -genomic_feature_disease_panel_id => $genomic_feature_disease_panel_id,
      -genomic_feature_disease_id => $genomic_feature_disease_id,
      -confidence_category => $confidence_category, 
      -confidence_category_attrib => $confidence_category_attrib,
      -is_visible => $is_visible,
      -panel => $panel,
      -panel_attrib => $panel_attrib,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
