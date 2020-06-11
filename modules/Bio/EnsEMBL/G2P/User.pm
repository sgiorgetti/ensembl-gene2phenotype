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
  my $panel = shift;
  my $attribute_adaptor = $self->{adaptor}->db->get_AttributeAdaptor;
  if ($panel) {
    my @values = split(',', $panel);
    my @ids = ();
    foreach my $value (@values) {
      push @ids, $attribute_adaptor->attrib_id_for_value($value);
    }
    $self->{panel_attrib} = join(',', @ids);
    $self->{panel} = $panel;
  } else {
    if (!$self->{panel} && $self->{panel_attrib}) {
      my @ids = split(',', $self->{panel_attrib});
      my @values = ();
      foreach my $id (@ids) {
        push @values, $attribute_adaptor->attrib_value_for_id($id);
      }
      $self->{panel} = join(',', @values);
    }
  }
  return $self->{panel};
}

sub panel_attrib {
  my $self = shift;
  $self->{panel_attrib} = shift if ( @_ );
  return $self->{panel_attrib};
}



1;
