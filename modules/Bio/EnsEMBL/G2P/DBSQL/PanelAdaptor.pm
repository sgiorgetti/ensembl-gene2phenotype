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

package Bio::EnsEMBL::G2P::DBSQL::PanelAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::Panel;
our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

=head2 store

  Arg [1]    : Bio::EnsEMBL::G2P::Panel $panel
  Example    : $panel = Bio::EnsEMBL::G2P::Panel->new(...);
               $panel = $panel_adaptor->store($panel);
  Description: This stores a Panel in the database.
  Returntype : Bio::EnsEMBL::G2P::Panel
  Exceptions : Throw error if $panel is not a Bio::EnsEMBL::G2P::Panel
  Caller     :
  Status     : Stable

=cut

sub store {
  my $self = shift;
  my $panel = shift;  

  if (!ref($panel) || !$panel->isa('Bio::EnsEMBL::G2P::Panel')) {
    die('Bio::EnsEMBL::G2P::Panel arg expected');
  }

  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO panel (
      name,
      is_visible, 
    ) VALUES (?, ?);
  });
  $sth->execute(
    $panel->name || undef,
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'panel', 'panel_id');
  $panel->{panel_id} = $dbID;
  return $panel;
}

sub update {
  my $self = shift;
  my $panel = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($panel) || !$panel->isa('Bio::EnsEMBL::G2P::Panel')) {
    die('Bio::EnsEMBL::G2P::Panel arg expected');
  }

  my $sth = $dbh->prepare(q{
    UPDATE panel
    SET name = ?,
        is_visible = ?
    WHERE panel_id = ?
  });
  $sth->execute(
    $panel->name,
    $panel->is_visible,
    $panel->dbID
  );
  $sth->finish();

  return $panel;
}

sub fetch_by_panel_id {
  my $self = shift;
  my $panel_id = shift;
  return $self->SUPER::fetch_by_dbID($panel_id);
}

sub fetch_by_dbID {
  my $self = shift;
  my $panel_id = shift;
  return $self->SUPER::fetch_by_dbID($panel_id);
}

sub fetch_by_name {
  my $self = shift;
  my $name = shift;
  my $constraint = "p.name='$name'";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_all {
  my $self = shift;
  return $self->generic_fetch();
}

sub fetch_all_visible {
  my $self = shift;
  my $constraint = "p.is_visible=1";
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'p.panel_id',
    'p.name',
    'p.is_visible',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['panel', 'p'],
  );
  return @tables;
}

=head2 _objs_from_sth

  Arg [1]    : StatementHandle $sth
  Description: Responsible for the creation of Panels
  Returntype : listref of Bio::EnsEMBL::G2P::Panel
  Exceptions : None
  Caller     : Internal
  Status     : Stable

=cut

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($panel_id, $name, $is_visible);
  $sth->bind_columns(\($panel_id, $name, $is_visible));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::Panel->new(
      -panel_id => $panel_id,
      -name => $name,
      -is_visible => $is_visible,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
