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

package Bio::EnsEMBL::G2P::DBSQL::UserAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::User;
our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');


=head2 store

  Arg [1]    : Bio::EnsEMBL::G2P::User $user
  Example    : $user = Bio::EnsEMBL::G2P::User->new(...);
               $user = $user_adaptor->store($user);
  Description: This stores a User in the database.
  Returntype : Bio::EnsEMBL::G2P::User
  Exceptions : - Throw error if $user is not a Bio::EnsEMBL::G2P::User
               - Throw error if neither panel nor panel_attrib
                 is provided
  Caller     :
  Status     : Stable

=cut

sub store {
  my $self = shift;
  my $user = shift;

  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die('Bio::EnsEMBL::G2P::User arg expected');
  }

  my $dbh = $self->dbc->db_handle;

  if (! (defined $user->{panel} || defined $user->{panel_attrib})) {
    die "panel or panel_attrib is required\n";
  }

  my $attribute_adaptor = $self->db->get_AttributeAdaptor;

  if (defined $user->{panel} && ! defined $user->{panel_attrib}) {
    $user->{panel_attrib} = $attribute_adaptor->get_attrib('g2p_panel', $user->{panel});
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO user (
      username,
      email,
      panel_attrib
    ) VALUES (?,?,?);
  });

  $sth->execute(
    $user->username,
    $user->email,
    $user->{panel_attrib},
  );

  $sth->finish();

  my $dbID = $dbh->last_insert_id(undef, undef, 'user', 'user_id');
  $user->{user_id} = $dbID;
  return $user;
}

sub fetch_by_dbID {
  my $self = shift;
  my $dbID = shift;
  return $self->SUPER::fetch_by_dbID($dbID);
}

sub fetch_by_email {
  my $self = shift;
  my $email = shift;
  my $constraint = "u.email='$email'";
  my $result = $self->generic_fetch($constraint); 
  return $result->[0];
}

sub fetch_by_username {
  my $self = shift;
  my $name = shift;
  my $constraint = "u.username='$name'";
  my $result = $self->generic_fetch($constraint); 
  return $result->[0];
}

=head2 _columns

  Description: Returns a list of columns to use for queries.
  Returntype : List of strings
  Exceptions : None
  Caller     : Internal
  Status     : Stable

=cut

sub _columns {
  my $self = shift;
  my @cols = (
    'u.user_id',
    'u.username',
    'u.email',
    'u.panel_attrib',
  );
  return @cols;
}

=head2 _tables

  Description: Returns the names, aliases of the tables to use for queries.
  Returntype : List of listrefs of strings
  Exceptions : None
  Caller     : Internal
  Status     : Stable

=cut

sub _tables {
  my $self = shift;
  my @tables = (
    ['user', 'u'],
  );
  return @tables;
}

=head2 _objs_from_sth

  Arg [1]    : StatementHandle $sth
  Description: Responsible for the creation of Users
  Returntype : listref of Bio::EnsEMBL::G2P::User 
  Exceptions : None
  Caller     : Internal
  Status     : Stable

=cut

sub _objs_from_sth {
  my ($self, $sth) = @_;
  my ($user_id, $username, $email, $panel_attrib);
  $sth->bind_columns(\($user_id, $username, $email, $panel_attrib));

  my @objs;
  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::User->new(
      -user_id => $user_id,
      -username => $username,
      -email => $email,
      -panel_attrib => $panel_attrib,
      -adaptor => $self,
    );
    push(@objs, $obj); 
  }  
  return \@objs;
}

1;
