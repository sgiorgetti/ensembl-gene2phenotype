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

use Bio::EnsEMBL::G2P::Utils::Net qw(do_GET do_POST);
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::Phenotype;
use JSON;
use Encode qw(decode encode);
our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

my $oxo_endpoint = 'https://www.ebi.ac.uk/spot/oxo/api/search/';

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

sub _insert_mesh2hp_mapping {
  my $self = shift;
  my $mesh_dbid = shift;
  my $hp_dbid = shift;
  my $dbh = $self->dbc->db_handle;
  my $sth = $dbh->prepare(q{
    INSERT IGNORE INTO phenotype_mapping(mesh_id, phenotype_id) VALUES (?, ?);
  });
  $sth->execute($mesh_dbid, $hp_dbid);
  $sth->finish();
}

sub store_mesh2hp_mappings {
  my $self = shift;
  my $mesh_phenotypes = shift;
  my $existing_mesh2hp_mappings = $self->_get_mesh2hp_mappings_from_db($mesh_phenotypes);
  my @existing_mesh_ids = keys %$existing_mesh2hp_mappings;
  my @new_mesh_phenotypes = ();
  foreach my $mesh_phenotype (@$mesh_phenotypes) {
    if (! grep {$mesh_phenotype->dbID == $_} @existing_mesh_ids) {
      push  @new_mesh_phenotypes, $mesh_phenotype;
    }
  }
  if (scalar @new_mesh_phenotypes > 0) {
    my @mesh_stable_ids = map {$_->stable_id} @new_mesh_phenotypes;
    my $mesh2hp_mappings = $self->_get_mesh2hp_mappings(\@mesh_stable_ids);

    foreach my $mesh_stable_id (keys %$mesh2hp_mappings) {
      foreach my $hp_stable_id (keys %{$mesh2hp_mappings->{$mesh_stable_id}}) {
        my $hp_phenotype = $self->fetch_by_stable_id($hp_stable_id);
        if ($hp_phenotype) {
          my ($mesh_phenotype) = grep {$_->stable_id eq $mesh_stable_id} @$mesh_phenotypes;
          $self->_insert_mesh2hp_mapping($mesh_phenotype->dbID, $hp_phenotype->dbID);
        }
      }
    }
  }
}

sub store_all_by_stable_ids_source {
  my $self = shift;
  my $stable_ids = shift;
  my $source = shift;
  my $add_mesh2hp_mappings = shift;

  my @mesh_phenotypes = @{$self->fetch_all_by_stable_ids_source($stable_ids, $source)};
  my @new_mesh_stable_ids = ();
  foreach my $stable_id (@$stable_ids) {
    if (! grep {$_->stable_id eq $stable_id } @mesh_phenotypes) {
      push  @new_mesh_stable_ids, $stable_id;
    }
  }

  my @new_mesh_phenotypes =  @{$self->_store_all_by_stable_ids_source(\@new_mesh_stable_ids, $source)} if (scalar @new_mesh_stable_ids);
  push @mesh_phenotypes, @new_mesh_phenotypes;

  if (@mesh_phenotypes) {
    $self->store_mesh2hp_mappings(\@mesh_phenotypes) if ($add_mesh2hp_mappings);
  }
  return \@mesh_phenotypes;
}

sub _store_all_by_stable_ids_source {
  my $self = shift;
  my $stable_ids = shift;
  my $source = shift;
  return $self->_store_by_stable_ids_MESH($stable_ids) if ($source eq "MESH");
}

sub store_by_stable_id_source {
  my $self = shift;
  my $stable_id = shift;
  my $source = shift;
  return $self->_store_by_stable_ids_MESH([$stable_id]) if ($source eq "MESH");
}

sub _store_by_stable_ids_MESH {
  my $self = shift;
  my $stable_ids = shift;
  my $source = 'MESH';
  my $data = {
    ids => $stable_ids,
    mappingTarget => [$source],
    distance => 1,
  };
  my @phenotypes = ();
  my $urls = _get_paged_urls($oxo_endpoint, $data);
  foreach my $url (@$urls) {
    my $content = do_POST($oxo_endpoint, $data);
    my $array = decode_json($content);
    my $results = $array->{_embedded}->{searchResults};
    foreach my $result (@$results) {
      next if (!$result->{mappingResponseList});
      my $mesh_stable_id = $result->{queryId};
      my $name = $result->{label};
      my $phenotype = Bio::EnsEMBL::G2P::Phenotype->new( 
        -stable_id => $mesh_stable_id,
        -name => $name,
        -source => $source,
        -adaptor => $self,
      );
      push @phenotypes, $self->store($phenotype);
      
    }
  }
  return \@phenotypes;
}

sub _get_mesh2hp_mappings_from_db {
  my $self = shift;
  my $mesh_phenotypes = shift;
  my $mesh_ids = join(',', map {$_->dbID} @$mesh_phenotypes);
  my $dbh = $self->dbc->db_handle;
  my $sth = $dbh->prepare(qq{
    SELECT mesh_id, phenotype_id FROM phenotype_mapping WHERE mesh_id IN ($mesh_ids);
  });
  $sth->execute();
  my $mesh2hp_phenotypes = {};
   while (my $row = $sth->fetchrow_arrayref) {
    my ($mesh_id, $phenotype_id) = @$row;
    $mesh2hp_phenotypes->{$mesh_id}->{$phenotype_id} = 1;
  }
  $sth->finish();
  return $mesh2hp_phenotypes;
}

sub _get_mesh2hp_mappings {
  my $self = shift;
  my $mesh_stable_ids = shift;
  my $mesh2hp_phenotypes = {};  
  my $data = {
    ids => $mesh_stable_ids,
    mappingTarget => ['HP'],
    distance => 1,
  };
  my $urls = _get_paged_urls($oxo_endpoint, $data);
  foreach my $url (@$urls) {
    my $content = do_POST($oxo_endpoint, $data);
    my $array = decode_json($content);
    my $results = $array->{_embedded}->{searchResults};
    foreach my $result (@$results) {
      next if (!$result->{mappingResponseList});
      my $mesh_stable_id = $result->{queryId};
      foreach my $item (@{$result->{mappingResponseList}}) {
        my $target_prefix = $item->{targetPrefix};
        my $hp_stable_id = $item->{curie};
        if ($target_prefix eq 'HP') {
          $mesh2hp_phenotypes->{$mesh_stable_id}->{$hp_stable_id} = 1;
        }
      }
    }
  }
  return $mesh2hp_phenotypes;
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
  my $names_concat = join(',', map {"'$_'"} @$names);
  my $constraint = "p.name IN ($names_concat)";
  return $self->generic_fetch($constraint);
}

sub fetch_all_by_stable_ids_source {
  my $self = shift;
  my $stable_ids = shift;
  my $source = shift;
  my $stable_ids_concat = join(',', map {"'$_'"} @$stable_ids);
  my $constraint = "p.stable_id IN ($stable_ids_concat) AND p.source='$source'";
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

sub _get_paged_urls {
  my $url = shift;
  my $data = shift;
  my $content = do_POST($url, $data);
  my $array = decode_json($content);
  my $page = $array->{page};
  if ($page) {
    my $page_number = $page->{number};
    my $total_pages = $page->{totalPages};
    return [$url] if ($total_pages <= 1);
    my $url = $array->{_links}->{first}->{href};
    my @urls = ();
    push @urls, $url;

    while ($page_number < $total_pages) {
      my $next_page_number = $page_number + 1;
      $url =~ s/page=$page_number/page=$next_page_number/;
      push @urls, $url;
      $page_number++;
    }
    return \@urls;
  }
  return [$url];
}



1;
