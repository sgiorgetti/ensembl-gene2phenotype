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

package Bio::EnsEMBL::G2P::DBSQL::OrganAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::Organ;
our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $organ = shift;  
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO organ (
      name
    ) VALUES (?);
  });
  $sth->execute(
    $organ->name || undef
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'organ', 'organ_id');
  $organ->{organ_id} = $dbID;
  return $organ;
}

sub fetch_by_organ_id {
  my $self = shift;
  my $organ_id = shift;
  return $self->SUPER::fetch_by_dbID($organ_id);
}

sub fetch_by_dbID {
  my $self = shift;
  my $organ_id = shift;
  return $self->SUPER::fetch_by_dbID($organ_id);
}

sub fetch_by_name {
  my $self = shift;
  my $name = shift;
  my $constraint = "o.name='$name'";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_all {
  my $self = shift;
  return $self->generic_fetch();
}

sub fetch_all_by_panel_id {
  my $self = shift;
  my $panel_id = shift;
  my $constraint = "op.panel_id=$panel_id";
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'o.organ_id',
    'o.name',
    'op.panel_id'
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['organ', 'o'],
    ['organ_panel', 'op']
  );
  return @tables;
}

sub _left_join {
  my $self = shift;

  my @left_join = (
    ['organ_panel', 'o.organ_id = op.organ_id'],
  );
  return @left_join;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($organ_id, $name, $panel_id);
  $sth->bind_columns(\($organ_id, $name, $panel_id));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::Organ->new(
      -organ_id => $organ_id,
      -name => $name,
      -panel_id => $panel_id,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
