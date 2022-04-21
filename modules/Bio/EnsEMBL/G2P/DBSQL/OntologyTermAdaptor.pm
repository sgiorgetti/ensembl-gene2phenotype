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

package Bio::EnsEMBL::G2P::DBSQL::OntologyTermAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::OntologyTerm;
use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $ontology_accession = shift; 

  if (!ref($ontology_accession) || !$ontology_accession->isa('Bio::EnsEMBL::G2P::OntologyTerm')) {
      die("Bio::EnsEMBL::G2P::OntologyTerm arg expected");
  }

  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO ontology_term (
      ontology_accession, 
      description
    ) VALUES (?,?)
  });

  $sth->execute(
      $ontology_accession->ontology_accession,
      $ontology_accession->description || undef,
  );

  $sth->finish();

  #get dbID 
  my $dbID = $dbh->last_insert_id(undef, undef, 'ontology_term', 'ontology_term_id');
  $ontology_accession->{ontology_term_id} = $dbID;
  
  return $ontology_accession;
}

sub update {
  my $self = shift;
  my $ontology_accession = shift; 
  my $dbh = $self->dbc->db_handle;

  if (!ref($ontology_accession) || !$ontology_accession->isa('Bio::EnsEMBL::G2P::OntologyTerm')) {
      die('Bio::EnsEMBL::G2P::OntologyTerm arg expected');
  }

  my $sth = $dbh->prepare(q{
      UPDATE ontology_term 
        SET ontology_accession = ?,
            description = ?
        WHERE ontology_term_id = ?
  }); 

  $sth->execute(
    $ontology_accession->ontology_accession,
    $ontology_accession->description || undef,
    $ontology_accession->dbID
  );

  $sth->finish();

  return $ontology_accession;
}

sub fetch_by_dbID {
  my $self = shift;
  my $ontology_term_id = shift;
  return $self->SUPER::fetch_by_dbID($ontology_term_id);
}

sub fetch_by_description {
  my $self = shift;
  my $description = shift; 
  $description =~ s/'/\\'/g;
  my $constraint = "ot.description='$description'";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_all_by_description {
  my $self = shift;
  my $description = shift;
  $description =~  s/'/\\'/g;
  my $constraint = "ot.description='$description'";
  my $result = $self->generic_fetch($constraint);
  return $result; 
}

sub fetch_by_accession {
  my $self = shift;
  my $ontology_accession = shift;
  my $constraint = "ot.ontology_accession='$ontology_accession'";
  my $result = $self->generic_fetch($constraint);
  return $result->[0]; 
}

sub _columns {
  my $self = shift;

  my @cols = (
    'ot.ontology_term_id',
    'ot.ontology_accession',
    'ot.description',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['ontology_term', 'ot'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($ontology_term_id, $ontology_accession, $description);
  $sth->bind_columns(\($ontology_term_id, $ontology_accession, $description));

  my @objs;
  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::OntologyTerm->new(
      -ontology_term_id => $ontology_term_id,
      -ontology_accession => $ontology_accession,
      -description => $description,
      -adaptor => $self,
    );
    push(@objs, $obj);    
  }
  return \@objs;
}

1; 
