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

package Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureAdaptor;

use Bio::EnsEMBL::G2P::GenomicFeature;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;

use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my ($self, $GF) = @_;
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature (
      gene_symbol,
      hgnc_id,
      mim,
      ensembl_stable_id,
      seq_region_id,
      seq_region_start,
      seq_region_end,
      seq_region_strand
    ) VALUES (?,?,?,?,?,?,?)
  });

  $sth->execute(
    $GF->gene_symbol,
    $GF->hgnc_id,
    $GF->mim,
    $GF->ensembl_stable_id,
    $GF->{seq_region_id} || undef,
    $GF->{seq_region_start} || undef,
    $GF->{seq_region_end} || undef,
    $GF->{seq_region_strand} || undef,
  );

  $sth->finish;

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature', 'genomic_feature_id');
  $GF->{dbID}    = $dbID;
  $GF->{adaptor} = $self;
}

sub update {
  my $self = shift;
  my $gf = shift;
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    UPDATE genomic_feature
      SET gene_symbol = ?,
          hgnc_id = ?,
          mim = ?,
          ensembl_stable_id = ?,
          seq_region_id = ?,
          seq_region_start = ?,
          seq_region_end = ?,
          seq_region_strand = ?
      WHERE genomic_feature_id  = ?
  });

  $sth->execute(
    $gf->gene_symbol,
    $gf->hgnc_id,
    $gf->mim,
    $gf->ensembl_stable_id,
    $gf->{seq_region_id} || undef,
    $gf->{seq_region_start} || undef,
    $gf->{seq_region_end} || undef,
    $gf->{seq_region_strand} || undef,
    $gf->{genomic_feature_id}
  );

  $sth->finish();
  return $gf;
}

sub fetch_all {
  my $self = shift;
  return $self->generic_fetch();
}

sub fetch_by_dbID {
  my $self = shift;
  my $genomic_feature_id = shift;
  return $self->SUPER::fetch_by_dbID($genomic_feature_id);
}

sub fetch_by_mim {
  my $self = shift;
  my $mim = shift;
  my $constraint = qq{gf.mim = ?};
  $self->bind_param_generic_fetch($mim, SQL_VARCHAR);
  my $result =  $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_by_gene_symbol {
  my $self = shift;
  my $gene_symbol = shift;
  my $constraint = qq{gf.gene_symbol = ?};
  $self->bind_param_generic_fetch($gene_symbol, SQL_VARCHAR);
  my $result =  $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_by_ensembl_stable_id {
  my $self = shift;
  my $ensembl_stable_id = shift;
  my $constraint = qq{gf.ensembl_stable_id = ?};
  $self->bind_param_generic_fetch($ensembl_stable_id, SQL_VARCHAR);
  my $result =  $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_by_synonym {
  my $self = shift;
  my $name = shift;
  # Do a query to get the current variation for the synonym and call a fetch method on this variation
  my $constraint = qq{ gfs.name = ? };

  # This statement will only return 1 row which is consistent with the behaviour of fetch_by_name.
  # However, the synonym name is only guaranteed to be unique in combination with the source 
  my $stmt = qq{ SELECT genomic_feature_id FROM genomic_feature_synonym gfs WHERE $constraint LIMIT 1};

  my $sth = $self->prepare($stmt);
  $sth->bind_param(1, $name, SQL_VARCHAR);
  $sth->execute();

  # Bind the results
  my $dbID;
  $sth->bind_columns(\$dbID);
  # Fetch the results
  $sth->fetch();

  # Return undef in case no data could be found
  return undef unless (defined $dbID );
  return $self->fetch_by_dbID($dbID);
}

sub fetch_all_by_substring {
  my $self = shift;
  my $substring = shift;
  my $constraint = "gf.gene_symbol LIKE '%$substring%' LIMIT 20"; 
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'gf.genomic_feature_id',
    'gf.gene_symbol',
    'gf.hgnc_id',
    'gf.mim',
    'gf.ensembl_stable_id',
    'gf.seq_region_id',
    'gf.seq_region_start',
    'gf.seq_region_end',
    'gf.seq_region_strand',
    'gfs.name AS gfs_name'
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['genomic_feature', 'gf'],
    ['genomic_feature_synonym', 'gfs'],
  );
  return @tables;
}

sub _left_join {
  my $self = shift;

  my @left_join = (
    ['genomic_feature_synonym', 'gf.genomic_feature_id = gfs.genomic_feature_id'],
  );
  return @left_join;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;
  my %row;
  $sth->bind_columns( \( @row{ @{$sth->{NAME_lc} } } ));
  while ($sth->fetch) {
    # we don't actually store the returned object because
    # the _obj_from_row method stores them in a temporary
    # hash _temp_objs in $self 
    $self->_obj_from_row(\%row);
  }

  # Get the created objects from the temporary hash
  my @objs = values %{ $self->{_temp_objs} };
  delete $self->{_temp_objs};

  # Return the created objects 
  return \@objs;
}

sub _obj_from_row {
  my ($self, $row) = @_;
  my $obj = $self->{_temp_objs}{$row->{genomic_feature_id}}; 
  unless ( defined $obj ) {
    $obj = Bio::EnsEMBL::G2P::GenomicFeature->new(
      -genomic_feature_id => $row->{genomic_feature_id},
      -gene_symbol => $row->{gene_symbol},
      -hgnc_id => $row->{hgnc_id},
      -mim => $row->{mim},
      -ensembl_stable_id => $row->{ensembl_stable_id},      
      -adaptor => $self,
    );

    $self->{_temp_objs}{$row->{genomic_feature_id}} = $obj;
  }

  # Add a synonym if available
  if (defined $row->{gfs_name} ) {
    $obj->add_synonym($row->{gfs_name});
  }
}

1;
