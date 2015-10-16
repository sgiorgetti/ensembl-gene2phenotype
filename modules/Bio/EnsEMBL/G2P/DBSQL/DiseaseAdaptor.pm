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

package Bio::EnsEMBL::G2P::DBSQL::DiseaseAdaptor;

use Bio::EnsEMBL::G2P::Disease;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub fetch_by_dbID {
  my $self = shift;
  my $disease_id = shift;
  return $self->SUPER::fetch_by_dbID($disease_id);
}

sub fetch_by_name {
  my $self = shift;
  my $name = shift;
  my $constraint = "d.name='$name'";
  my $result = $self->generic_fetch($constraint);
  $result->[0];
}

sub fetch_by_mim {
  my $self = shift;
  my $mim = shift;
  my $constraint = "d.mim=$mim";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub _columns {
  my $self = shift;
  my @cols = (
    'd.disease_id',
    'd.name',
    'd.mim',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['disease', 'd'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($disease_id, $name, $mim);
  $sth->bind_columns(\($disease_id, $name, $mim));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::Disease->new(
      -disease_id => $disease_id,
      -name => $name,
      -mim => $mim,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}
1;
