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

package Bio::EnsEMBL::G2P::User;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($user_id, $username, $email, $panel, $panel_attrib, $adaptor) = 
    rearrange(['user_id', 'username', 'email', 'panel', 'panel_attrib', 'adaptor'], @_);

  my $self = bless {
    'user_id' => $user_id,
    'username' => $username,
    'email' => $email,
    'panel' => $panel,
    'panel_attrib' => $panel_attrib,
    'adaptor' => $adaptor,
  }, $class;
  return $self;
}

sub dbID {
  my $self = shift;
  $self->{user_id} = shift if ( @_ );
  return $self->{user_id};
}

sub user_id {
  my $self = shift;
  return $self->{user_id};
}

sub username {
  my $self = shift;
  $self->{username} = shift if ( @_ );
  return $self->{username};
}

sub email {
  my $self = shift;
  $self->{email} = shift if ( @_ );
  return $self->{email};
}

sub panel {
  my $self = shift;

  my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;
  if (!$self->{panel} && $self->{panel_attrib} ) {
    $self->{panel} = $attribute_adaptor->get_value('g2p_panel', $self->{panel_attrib});
  }
  return $self->{panel};
}

sub panel_attrib {
  my $self = shift;
  $self->{panel_attrib} = shift if ( @_ );
  return $self->{panel_attrib};
}

1;
