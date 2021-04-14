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

package Bio::EnsEMBL::G2P::DBSQL::AttributeAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor'); 


sub get_attrib {
  my $self = shift;
  my $type = shift;
  my $value = shift;

  if ($type eq 'allelic_requirement') {
    my @ids = ();
    foreach my $v (split(',', $value)) {
      my $id = $self->attrib_id_for_type_value($type, $v);
      if (!$id) {
        die "Could not get attrib for value: $v\n";
      }
      push @ids, $self->attrib_id_for_type_value($type, $v);
    }        
    return join(',', sort @ids);
  } else {
    my $attrib = $self->attrib_id_for_type_value($type, $value);
    if (!$attrib) {
      die "Could not get attrib for value: $value\n";
    }
    return $attrib;
  }
}

sub get_value {
  my $self = shift;
  my $type = shift;
  my $attrib = shift;

  if ($type eq 'allelic_requirement') {
    my @values = ();
    foreach my $id (split(',', $attrib)) {
      my $value =  $self->attrib_value_for_type_id($type, $id);
      if (!$value) {
        die "Could not get value for attrib: $id\n";
      }
      push @values, $value;
    }
    return join(',', sort @values);
  } else {
    my $value = $self->attrib_value_for_type_id($type, $attrib);
    if (!$value) {
      die "Could not get value for attrib: $attrib\n";
    }
    return $value;
  }
}

sub set_attribs {
  my $self = shift;

  unless ($self->{attribs}) {
    my $attribs;
    my $attrib_ids;
    my $attrib_values;
    my $sql = qq{
      SELECT  a.attrib_id, t.code, a.value
      FROM    attrib a, attrib_type t
      WHERE   a.attrib_type_id = t.attrib_type_id
    };

    my $dbh = $self->dbc->db_handle;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    while (my ($attrib_id, $type, $value) = $sth->fetchrow_array) {
      $attribs->{$attrib_id}->{type}  = $type;
      $attribs->{$attrib_id}->{value} = $value;
      $attrib_ids->{$type}->{$value} = $attrib_id;
      $attrib_values->{$type}->{$attrib_id} = $value;
    }
    $self->{attribs}    = $attribs;
    $self->{attrib_ids} = $attrib_ids;
    $self->{attrib_values} = $attrib_values;
  }
}

sub attrib_id_for_type_value {
  my ($self, $type, $value) = @_;
  unless ($self->{attrib_ids}) {
    $self->set_attribs;
  }
  return $self->{attrib_ids}->{$type}->{$value};
}

sub attrib_value_for_type_id {
  my ($self, $type, $attrib_id) = @_;
  unless ($self->{attrib_values}) {
    $self->set_attribs;
  }
  return $self->{attrib_values}->{$type}->{$attrib_id};
}

sub get_attribs_by_type {
  my ($self, $attrib_type_code) = @_;
  my $attribs = {};
  my $sql = qq{
    SELECT  a.attrib_id, a.value
    FROM    attrib a, attrib_type t
    WHERE   a.attrib_type_id = t.attrib_type_id
    AND     t.code = ?;
  };

  my $dbh = $self->dbc->db_handle;
  my $sth = $dbh->prepare($sql);
  $sth->execute($attrib_type_code);

  while (my ($attrib_id, $value) = $sth->fetchrow_array) {
    $attribs->{$value} = $attrib_id;
  }
  $sth->finish();
  return $attribs;
}



1;
