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

package Bio::EnsEMBL::G2P::DBSQL::OrganAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::Organ;
our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

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
  return $self->generic_fetch_all();
}

sub _columns {
  my $self = shift;
  my @cols = (
    'o.organ_id',
    'o.name',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['organ', 'o'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($organ_id, $name);
  $sth->bind_columns(\($organ_id, $name));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::Organ->new(
      -organ_id => $organ_id,
      -name => $name,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
