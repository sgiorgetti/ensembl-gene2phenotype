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

package Bio::EnsEMBL::G2P::DBSQL::PhenotypeAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::Phenotype;
use JSON;
use Encode qw(decode encode);
our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $phenotype = shift;  
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO phenotype (
      stable_id,
      name,
      description,
      source
    ) VALUES (?,?,?,?);
  });
  $sth->execute(
    $phenotype->stable_id || undef,
    $phenotype->name || undef,
    $phenotype->description || undef,
    $phenotype->source || undef,
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
          description = ?,
          source = ?
      WHERE phenotype_id = ? 
  });
  $sth->execute(
    $phenotype->{stable_id},
    $phenotype->{name},
    $phenotype->{description},
    $phenotype->{source},
    $phenotype->dbID
  );
  $sth->finish();

  return $phenotype;
}

sub _delete_existing_phenotype_mappings {
  my $self = shift;
  my $phenotype = shift;
  my $dbh = $self->dbc->db_handle;
  my $sth = $dbh->prepare(q{
    DELETE FROM phenotype_mapping WHERE mesh_id  = ?;
  });
  $sth->execute($phenotype->dbID);
  $sth->finish();
}

sub _insert_mesh_2_hp_mapping {
  my $self = shift;
  my $mesh_dbid = shift;
  my $hp_dbid = shift;
  my $dbh = $self->dbc->db_handle;
  my $sth = $dbh->prepare(q{
    INSERT INTO phenotype_mapping(mesh_id, phenotype_id) VALUES (?, ?);
  });
  $sth->execute($mesh_dbid, $hp_dbid);
  $sth->finish();
}

sub store_mappings_to_hp {
  my $self = shift;
  my $mesh_phenotypes = shift;
  foreach my $mesh_phenotype (@$mesh_phenotypes) {
    $self->_delete_existing_phenotype_mappings($mesh_phenotype);
    my $hp_phenotypes = $self->_get_hp_mappings($mesh_phenotype);    
    foreach my $hp_phenotype (@$hp_phenotypes) {
      my $hp_phenotype = $self->fetch_by_stable_id($hp_phenotype);
      if ($hp_phenotype) {
        $self->_insert_mesh_2_hp_mapping($mesh_phenotype->dbID, $hp_phenotype->dbID);
      }
    }
  }
}

sub store_mesh_phenotype {
  my $self = shift;
  my $stable_id = shift;

  my $data = {
    ids => [$stable_id],
    mappingTarget => ['MESH'],
    distance => 1,
  };
  my $http = HTTP::Tiny->new();
  my $server = 'https://www.ebi.ac.uk/spot/oxo/api/search/';
  my $response = $http->post_form($server, $data,
  {
    'Content-type' => 'application/json',
    'Accept' => 'application/json'
  },);

  die "Failed!\n" unless $response->{success};
  my $array = decode_json($response->{content});
  my $results = $array->{_embedded}->{searchResults};
  my $name = $results->[0]->{label};

  my $phenotype = Bio::EnsEMBL::G2P::Phenotype->new( 
    -stable_id => $stable_id,
    -name => $name,
    -source => 'MESH',
    -adaptor => $self,
  );
  return $self->store($phenotype);
}

sub _get_hp_mappings {
  my $self = shift;
  my $mesh_phenotype = shift;
  my $hp_phenotypes = {};  
  my $data = {
    ids => [$mesh_phenotype->stable_id],
    mappingTarget => ['HP'],
    distance => 1,
  };
  my $http = HTTP::Tiny->new();
  my $server = 'https://www.ebi.ac.uk/spot/oxo/api/search/';
  my $response = $http->post_form($server, $data,
  {
    'Content-type' => 'application/json',
    'Accept' => 'application/json'
  },);

  die "Failed!\n" unless $response->{success};
  my $array = decode_json($response->{content});
  my $results = $array->{_embedded}->{searchResults};
  foreach my $result (@$results) {
    next if (!$result->{mappingResponseList});
    my $query_id = $result->{queryId};
    foreach my $item (@{$result->{mappingResponseList}}) {
      my $target_prefix = $item->{targetPrefix};
      my $label = $item->{label}; 
      my $hp_stable_id = $item->{curie};
      if ($target_prefix eq 'HP') {
        $hp_phenotypes->{$hp_stable_id} = 1;
      }
    }
  }
  my @return = keys %$hp_phenotypes;
  return \@return;
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

sub fetch_by_stable_id_source {
  my $self = shift;
  my $stable_id = shift;
  my $source = shift;
  my $constraint = "p.stable_id='$stable_id' AND p.source='$source'";
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

sub fetch_all_by_name_list_source {
  my $self = shift;
  my $names = shift;
  my $source = shift;
  my $names_concat = join(',', @$names);
  my $constraint = "p.stable_id IN ($names_concat)";
  return $self->generic_fetch($constraint);
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
    'p.source',
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

  my ($phenotype_id, $stable_id, $name, $description, $source);
  $sth->bind_columns(\($phenotype_id, $stable_id, $name, $description, $source));

  my @objs;
  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::Phenotype->new(
      -phenotype_id => $phenotype_id,
      -stable_id => $stable_id,
      -name => $name, 
      -description => $description,
      -source => $source,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
