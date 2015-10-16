=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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


sub store {
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

sub _columns {
  my $self = shift;
  my @cols = (
    'u.user_id',
    'u.username',
    'u.email',
    'u.panel',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['user', 'u'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;
  my ($user_id, $username, $email, $panel);
  $sth->bind_columns(\($user_id, $username, $email, $panel));

  my @objs;
  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::User->new(
      -user_id => $user_id,
      -username => $username,
      -email => $email,
      -panel => $panel,
      -adaptor => $self,
    );
    push(@objs, $obj); 
  }  
  return \@objs;
}

1;
