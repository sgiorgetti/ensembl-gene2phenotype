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

package Bio::EnsEMBL::G2P::DBSQL::PhenotypeAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::Phenotype;
our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');


sub store {
}

sub update {
}

sub fetch_by_phenotype_id {
  my $self = shift;
  my $phenotype_id = shift;
  $self->fetch_by_dbID($phenotype_id);
}

sub fetch_by_dbID {
  my $self = shift;
  my $phenotype_id = shift;
  return $self->SUPER::fetch_by_dbID($phenotype_id);
}

sub fetch_by_stable_id {
  my $self = shift;
  my $stable_id = shift;
  my $constraint = "p.stable_id='$stable_id'";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
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
  return $self->fetch_all();
}

sub _columns {
  my $self = shift;
  my @cols = (
    'p.phenotype_id',
    'p.stable_id',
    'p.name',
    'p.description',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['phenotype', 'p'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($phenotype_id, $stable_id, $name, $description);
  $sth->bind_columns(\($phenotype_id, $stable_id, $name, $description));

  my @objs;
  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::Phenotype->new(
      -phenoype_id => $phenotype_id,
      -stable_id => $stable_id,
      -name => $name, 
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
