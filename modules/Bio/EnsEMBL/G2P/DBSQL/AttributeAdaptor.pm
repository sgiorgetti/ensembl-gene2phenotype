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

package Bio::EnsEMBL::G2P::DBSQL::AttributeAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor'); 

sub attrib_id_for_value {
  my ($self, $attrib_value) = @_;
  my $sql = qq{
    SELECT attrib_id FROM attrib WHERE value=?;
  };
  my $dbh = $self->dbc->db_handle;
  my $sth = $dbh->prepare($sql);
  $sth->execute($attrib_value);
  my $attrib_id;
  $sth->bind_columns(\$attrib_id);
  $sth->fetch;
  $sth->finish;
  return $attrib_id;  
}

sub attrib_value_for_id {
  my ($self, $attrib_id) = @_;

  unless ($self->{attribs}) {
    my $attribs;
    my $attrib_ids;

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
    }

    $self->{attribs}    = $attribs;
    $self->{attrib_ids} = $attrib_ids;

  }
  return defined $attrib_id ? $self->{attribs}->{$attrib_id}->{value} : undef;
}

sub attrib_id_for_type_value {
  my ($self, $type, $value) = @_;
  unless ($self->{attrib_ids}) {
    # call this method to populate the attrib hash
    $self->attrib_value_for_id;
  }

  return $self->{attrib_ids}->{$type}->{$value};
}

sub get_attribs_by_type_value {
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
