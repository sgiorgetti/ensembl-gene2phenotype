=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute
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

package Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseAdaptor;

use Bio::EnsEMBL::G2P::GenomicFeatureDisease;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $gfd = shift;
  my $user = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($gfd) || !$gfd->isa('Bio::EnsEMBL::G2P::GenomicFeatureDisease')) {
    die('Bio::EnsEMBL::G2P::GenomicFeatureDisease arg expected');
  }

  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die('Bio::EnsEMBL::G2P::User arg expected');
  }

  if (! (defined $gfd->{panel} || defined $gfd->{panel_attrib})) {
    die "panel or panel_attrib is required\n";
  }

  if (! (defined $gfd->{confidence_category} || defined $gfd->{confidence_category_attrib})) {
    die "confidence_category or confidence_category_attrib is required\n";
  }

  my $aa = $self->db->get_AttributeAdaptor;
  if ( defined $gfd->{panel} ) {
    my $panel_attrib = $aa->attrib_id_for_type_value('g2p_panel', $gfd->{panel});
    die "Could not get panel attrib id for value ", $gfd->{panel}, "\n" unless ($panel_attrib);
    $gfd->{panel_attrib} = $panel_attrib;
  }

  if ( defined $gfd->{confidence_category} ) {
    my $confidence_category_attrib = $aa->attrib_id_for_type_value('confidence_category', $gfd->{confidence_category});
    die "Could not get confidence category attrib id for value ", $gfd->{confidence_category}, "\n" unless ($confidence_category_attrib);
    $gfd->{confidence_category_attrib} = $confidence_category_attrib;
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease(
      genomic_feature_id,
      disease_id,
      confidence_category_attrib,
      is_visible,
      panel_attrib
    ) VALUES (?, ?, ?, ?, ?)
  });

  $sth->execute(
    $gfd->{genomic_feature_id},
    $gfd->{disease_id},
    $gfd->{confidence_category_attrib},
    $gfd->is_visible || 1,
    $gfd->{panel_attrib},
  );

  $sth->finish();
  
  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease', 'genomic_feature_disease_id'); 
  $gfd->{genomic_feature_disease_id} = $dbID;

  $self->update_log($gfd, $user, 'create');

  return $gfd;
}

sub delete {
 my $self = shift;
  my $GFD = shift;
  my $user = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($GFD) || !$GFD->isa('Bio::EnsEMBL::G2P::GenomicFeatureDisease')) {
    die ('Bio::EnsEMBL::G2P::GenomicFeatureDisease arg expected');
  }

  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die ('Bio::EnsEMBL::G2P::User arg expected');
  }

  my $GFD_id = $GFD->dbID; 

  my $GFDPublicationAdaptor = $self->db->get_GenomicFeatureDiseasePublicationAdaptor;
  foreach my $GFDPublication (@{$GFD->get_all_GFDPublications}) {
    $GFDPublicationAdaptor->delete($GFDPublication, $user);
  }

  my $GFDPhenotypeAdaptor = $self->db->get_GenomicFeatureDiseasePhenotypeAdaptor;
  foreach my $GFDPhenotype (@{$GFD->get_all_GFDPhenotypes}) {
    $GFDPhenotypeAdaptor->delete($GFDPhenotype, $user);
  }     
  
  my $GFDOrganAdaptor = $self->db->get_GenomicFeatureDiseaseOrganAdaptor;
  foreach my $GFDOrgan (@{$GFD->get_all_GFDOrgans}) {
    $GFDOrganAdaptor->delete($GFDOrgan, $user);
  }   
    
  my $GenomicFeatureDiseaseActionAdaptor = $self->db->get_GenomicFeatureDiseaseActionAdaptor; 
  foreach my $GFDAction (@{$GFD->get_all_GenomicFeatureDiseaseActions}) {
    $GenomicFeatureDiseaseActionAdaptor->delete($GFDAction, $user);
  }

  my $GenomicFeatureDiseaseLogAdaptor = $self->db->get_GenomicFeatureDiseaseLogAdaptor; 
  foreach my $log_entry (@{$GenomicFeatureDiseaseLogAdaptor->fetch_all_by_GenomicFeatureDisease($GFD)}) {
    $GenomicFeatureDiseaseLogAdaptor->delete($log_entry, $user);
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_deleted (
      genomic_feature_disease_id,
      genomic_feature_id,
      disease_id,
      confidence_category_attrib,
      is_visible,
      panel_attrib,
      deleted,
      deleted_by_user_id
    ) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?)
  });

  $sth->execute(
    $GFD->dbID,
    $GFD->genomic_feature_id,
    $GFD->disease_id,
    $GFD->confidence_category_attrib,
    $GFD->is_visible,
    $GFD->panel_attrib,
    $user->user_id
  );
  $sth->finish();

  $sth = $dbh->prepare(q{
    DELETE FROM genomic_feature_disease WHERE genomic_feature_disease_id = ?;
  });

  $sth->execute($GFD->dbID);
  $sth->finish();
}

sub update {
  my $self = shift;
  my $gfd = shift;
  my $user = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($gfd) || !$gfd->isa('Bio::EnsEMBL::G2P::GenomicFeatureDisease')) {
    die('Bio::EnsEMBL::G2P::GenomicFeatureDisease arg expected');
  }

  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die('Bio::EnsEMBL::G2P::User arg expected');
  }

  my $sth = $dbh->prepare(q{
    UPDATE genomic_feature_disease
      SET genomic_feature_id = ?,
        disease_id = ?,
        confidence_category_attrib = ?,
        is_visible = ?,
        panel_attrib = ?
      WHERE genomic_feature_disease_id = ? 
  });
  $sth->execute(
    $gfd->genomic_feature_id,
    $gfd->disease_id,
    $gfd->confidence_category_attrib,
    $gfd->is_visible,
    $gfd->panel_attrib,
    $gfd->dbID
  );
  $sth->finish();

  $self->update_log($gfd, $user, 'update');

  return $gfd;
}

sub update_log {
  my $self = shift;
  my $gfd = shift;
  my $user = shift;
  my $action = shift;

  my $GFD_log_adaptor = $self->db->get_GenomicFeatureDiseaseLogAdaptor;
  my $gfdl = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseLog->new(
    -genomic_feature_disease_id => $gfd->dbID,
    -is_visible => $gfd->is_visible,
    -panel_attrib => $gfd->panel_attrib,
    -disease_id => $gfd->disease_id,
    -genomic_feature_id => $gfd->genomic_feature_id,
    -confidence_category_attrib => $gfd->confidence_category_attrib,
    -user_id => $user->dbID,
    -action => $action, 
    -adaptor => $GFD_log_adaptor,
  );
  $GFD_log_adaptor->store($gfdl);
}

sub fetch_by_dbID {
  my $self = shift;
  my $genomic_feature_disease_id = shift;
  return $self->SUPER::fetch_by_dbID($genomic_feature_disease_id);
}

sub fetch_by_GenomicFeature_Disease {
  my $self = shift;
  my $genomic_feature = shift;
  my $disease = shift;
  my $genomic_feature_id = $genomic_feature->dbID;
  my $disease_id = $disease->dbID;
  my $constraint = "gfd.disease_id=$disease_id AND gfd.genomic_feature_id=$genomic_feature_id;";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_by_GenomicFeature_Disease_panel_id {
  my $self = shift;
  my $genomic_feature = shift;
  my $disease = shift;
  my $panel_id = shift;
  my $genomic_feature_id = $genomic_feature->dbID;
  my $disease_id = $disease->dbID;
  my $constraint = "gfd.disease_id=$disease_id AND gfd.genomic_feature_id=$genomic_feature_id AND gfd.panel_attrib=$panel_id;";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_by_GenomicFeature_Disease_panel {
  my $self = shift;
  my $genomic_feature = shift;
  my $disease = shift;
  my $panel = shift;
  my $attribute_adaptor = $self->db->get_AttributeAdaptor;
  my $panel_id = $attribute_adaptor->attrib_id_for_value($panel);
  return $self->fetch_by_GenomicFeature_Disease_panel_id($genomic_feature, $disease, $panel_id);
}

sub fetch_all_by_GenomicFeature {
  my $self = shift;
  my $genomic_feature = shift;
  my $genomic_feature_id = $genomic_feature->dbID;
  my $constraint = "gfd.genomic_feature_id=$genomic_feature_id";
  return $self->generic_fetch($constraint);
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
  my $constraint = "gfd.genomic_feature_id=$genomic_feature_id AND gfd.panel_attrib=$panel_id";
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
  my $constraint = "gfd.genomic_feature_id=$genomic_feature_id AND gfd.panel_attrib IN (" . join(',', @panel_ids) . ")";
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_Disease {
  my $self = shift;
  my $disease = shift;
  my $disease_id = $disease->dbID;
  my $constraint = "gfd.disease_id=$disease_id";
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
  my $constraint = "gfd.disease_id=$disease_id AND gfd.panel_attrib=$panel_id";
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
  my $constraint = "gfd.disease_id=$disease_id AND gfd.panel_attrib IN (" . join(',', @panel_ids) . ")";
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_disease_id {
  my $self = shift;
  my $disease_id = shift;
  my $constraint = qq{gfd.disease_id = ?};
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
  my $constraint = "gfd.panel_attrib=$panel_id";
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
  my $constraint = "gfd.panel_attrib=$panel_id AND gfd.is_visible = 0";
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
    select a.value, gfd.confidence_category_attrib, count(*)
    from genomic_feature_disease gfd, attrib a
    where a.attrib_id = gfd.panel_attrib
    AND gfd.panel_attrib IN ($panel_attrib_ids)
    group by a.value, gfd.confidence_category_attrib;
  });
  $sth->execute;

  my $hash = {};
  while (my ($panel, $confidence_category_attrib_id, $count) = $sth->fetchrow_array) {
    my $confidence_category_value = $confidence_categories->{$confidence_category_attrib_id};
    $hash->{$panel}->{$confidence_category_value} = $count;
  }
  my @results = ();
  my @header = ('Panel', 'confirmed', 'probable', 'possible', 'both DD and IF', 'child IF'); 
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
    $constraint = "AND gfd.panel_attrib=$panel_id";
  } 
  my $cols = join ",", $self->_columns();
  my $sth = $self->prepare(qq{
    SELECT $cols FROM genomic_feature_disease gfd
    LEFT JOIN genomic_feature_disease_publication gfdp
    ON gfd.genomic_feature_disease_id = gfdp.genomic_feature_disease_id
    WHERE gfdp.genomic_feature_disease_id IS NULL
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
    'gfd.genomic_feature_disease_id',
    'gfd.genomic_feature_id',
    'gfd.disease_id',
    'gfd.confidence_category_attrib',
    'gfd.is_visible',
    'gfd.panel_attrib',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['genomic_feature_disease', 'gfd'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($genomic_feature_disease_id, $genomic_feature_id, $disease_id, $confidence_category_attrib, $is_visible, $panel_attrib);
  $sth->bind_columns(\($genomic_feature_disease_id, $genomic_feature_id, $disease_id, $confidence_category_attrib, $is_visible, $panel_attrib));

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

    my $obj = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
      -genomic_feature_disease_id => $genomic_feature_disease_id,
      -genomic_feature_id => $genomic_feature_id,
      -disease_id => $disease_id,
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
