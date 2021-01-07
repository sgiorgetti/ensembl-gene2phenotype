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

package Bio::EnsEMBL::G2P::DBSQL::LGMPanelDiseaseAdaptor;

use DBI qw(:sql_types);
use Bio::EnsEMBL::G2P::LGMPanelDisease;
our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $lgm_panel_disease = shift;

  if (!ref($lgm_panel_disease) || !$lgm_panel_disease->isa('Bio::EnsEMBL::G2P::LGMPanelDisease')) {
    die('Bio::EnsEMBL::G2P::LGMPanelDisease arg expected');
  }

  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO LGM_panel_disease(
      LGM_panel_id,
      disease_id,
      user_id,
      created
    ) VALUES (?, ?, ?, CURRENT_TIMESTAMP)
  });

  $sth->execute(
    $lgm_panel_disease->LGM_panel_id,
    $lgm_panel_disease->disease_id,
    $lgm_panel_disease->user_id
  );

  $sth->finish();
  
  my $dbID = $dbh->last_insert_id(undef, undef, 'LGM_panel_disease', 'LGM_panel_disease_id'); 
  $lgm_panel_disease->{LGM_panel_disease_id} = $dbID;

  return $lgm_panel_disease;
}

sub fetch_by_dbID {
  my $self = shift;
  my $dbID = shift;
  return $self->SUPER::fetch_by_dbID($dbID);
}

sub fetch_all {
  my $self = shift;
  return $self->generic_fetch();
}

sub fetch_all_by_LGMPanel {
  my $self = shift;
  my $lgm_panel = shift;
  my $lgm_panel_id = $lgm_panel->dbID;
  my $constraint = "LGM_panel_id=$lgm_panel_id;";
  return $self->generic_fetch($constraint);
}

sub fetch_by_LGMPanel_Disease {
  my $self = shift;
  my $LGM_panel = shift;
  my $disease = shift;
  my $LGM_panel_id = $LGM_panel->dbID;
  my $disease_id = $disease->dbID;
  my $constraint = "LGM_panel_id=$LGM_panel_id AND disease_id=$disease_id;";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub _columns {
  my $self = shift;
  my @cols = (
    'LGM_panel_disease_id',
    'LGM_panel_id',
    'disease_id',
    'user_id',
    'created',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['LGM_panel_disease', 'lgmpd'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;
  my ($LGM_panel_disease_id, $LGM_panel_id, $disease_id, $user_id, $created);
  $sth->bind_columns(\($LGM_panel_disease_id, $LGM_panel_id, $disease_id, $user_id, $created));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::LGMPanelDisease->new(
      -LGM_panel_disease_id => $LGM_panel_disease_id,
      -LGM_panel_id => $LGM_panel_id,
      -disease_id => $disease_id,
      -user_id => $user_id,
      -created => $created,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
