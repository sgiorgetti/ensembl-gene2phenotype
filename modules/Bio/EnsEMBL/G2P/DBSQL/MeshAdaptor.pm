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

package Bio::EnsEMBL::G2P::DBSQL::PhenotypeAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::Phenotype;
our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $phenotype = shift;  
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO phenotype (
      stable_id,
      name,
      description
    ) VALUES (?,?,?);
  });
  $sth->execute(
    $phenotype->stable_id || undef,
    $phenotype->name || undef,
    $phenotype->description || undef,
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'phenotype', 'phenotype_id');
  $phenotype->{phenotype_id} = $dbID;
  return $phenotype;
}

sub update {
  my $self = shift;
  my $phenotype = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($phenotype) || !$phenotype->isa('Bio::EnsEMBL::G2P::Phenotype')) {
    die('Bio::EnsEMBL::G2P::Phenotype arg expected');
  }

  my $sth = $dbh->prepare(q{
    UPDATE phenotype
      SET stable_id = ?,
          name = ?,
          description = ?
      WHERE phenotype_id = ? 
  });
  $sth->execute(
    $phenotype->{stable_id},
    $phenotype->{name},
    $phenotype->{description},
    $phenotype->dbID
  );
  $sth->finish();

  return $phenotype;
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
  return $self->generic_fetch();
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
      -phenotype_id => $phenotype_id,
      -stable_id => $stable_id,
      -name => $name, 
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
