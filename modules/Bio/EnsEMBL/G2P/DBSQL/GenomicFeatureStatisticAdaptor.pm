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

package Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureStatisticAdaptor;

use Bio::EnsEMBL::G2P::GenomicFeatureStatistic;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::Utils::Exception qw(throw warning);
use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $gfs = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($gfs) || !$gfs->isa('Bio::EnsEMBL::G2P::GenomicFeatureStatistic')) {
    die('Bio::EnsEMBL::G2P::GenomicFeatureStatistic arg expected');
  }

  my $sth = $dbh->prepare(q{
        INSERT INTO genomic_feature_statistic (
            genomic_feature_id,
            panel_attrib
        ) VALUES (?, ?)
    });

  $sth->execute(
    $gfs->genomic_feature_id(),
    $gfs->panel_attrib()
  );
  
  $sth->finish;

   # get dbID
   my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_statistic', 'genomic_feature_id');
   $gfs->{dbID}    = $dbID;
   $gfs->{adaptor} = $self;
   
   # add genomic_feature_statistic attributes
   my $aa = $self->db->get_AttributeAdaptor;
   my $gfsa_sth = $dbh->prepare(q{
        INSERT INTO genomic_feature_statistic_attrib (
            genomic_feature_statistic_id,
            attrib_type_id,
            value                  
        ) VALUES (?,?,?)
    });
  foreach my $attrib_type( keys %{$gfs->{attribs}} ){
    my $attrib_type_id = $aa->attrib_id_for_type_code($attrib_type);
    throw("No attrib type ID found for attrib_type $attrib_type") unless defined  $attrib_type_id;
    $gfs->{attribs}->{$attrib_type} =~ s/\s+$//;
    $gfsa_sth->execute( $gfs->{dbID}, $attrib_type_id, $gfs->{attribs}->{$attrib_type} );
  }
  $gfsa_sth->finish;
}


sub fetch_all {
  my $self = shift;
  return $self->generic_fetch();
}

sub fetch_all_by_GenomicFeature_panel_attrib {
  my $self = shift;
  my $gf = shift;
  my $panel_attrib = shift;
  my $constraint = "gfs.genomic_feature_id=" . $gf->dbID . " AND gfs.panel_attrib=" . $panel_attrib;
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'gfs.genomic_feature_statistic_id',
    'gfs.genomic_feature_id',
    'gfs.panel_attrib',
    'gfsa.value',
    'at.code'
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  
  my @tables = (
    [ 'genomic_feature_statistic', 'gfs' ],
    [ 'genomic_feature_statistic_attrib', 'gfsa' ],
    [ 'attrib_type', 'at' ]
  );
 
  return @tables; 
}

sub _left_join {
  my $self = shift;
  
  my @left_join = (
    [ 'genomic_feature_statistic_attrib', 'gfs.genomic_feature_statistic_id = gfsa.genomic_feature_statistic_id' ],
    [ 'attrib_type', 'gfsa.attrib_type_id = at.attrib_type_id' ]
  );
  
  return @left_join;
}


sub _objs_from_sth {
  my ($self, $sth, $mapper, $dest_slice) = @_;
   
  my %row;
  # Create the row hash using column names as keys
  $sth->bind_columns( \( @row{ @{$sth->{NAME_lc} } } ));

  while ($sth->fetch) {

      # we don't actually store the returned object because
      # the _obj_from_row method stores them in a temporary
      # hash _temp_objs in $self 
      $self->_obj_from_row(\%row, $mapper, $dest_slice);
  }

  # Get the created objects from the temporary hash
  my @objs = values %{ $self->{_temp_objs} };
  delete $self->{_temp_objs};
 
  # Return the created objects 
  return \@objs;
}

sub _obj_from_row {
  my ($self, $row) = @_;
  my $obj = $self->{_temp_objs}{$row->{genomic_feature_statistic_id}}; 
    
  unless (defined($obj)) {

    my $seq_region_start   = $row->{seq_region_start};
    my $seq_region_end     = $row->{seq_region_end};
    my $seq_region_strand  = $row->{seq_region_strand};

    $obj = Bio::EnsEMBL::G2P::GenomicFeatureStatistic->new(
      -dbID => $row->{genomic_feature_statistic_id},
      -genomic_feature_id => $row->{genomic_feature_id}, 
      -panel_attrib => $row->{panel_attrib}, 
      -adaptor => $self,
    );

    $self->{_temp_objs}{$row->{genomic_feature_statistic_id}} = $obj;
  }

  ## add attribs if extracted
  $obj->{attribs}->{$row->{code}} = $row->{value} if $row->{code};

}


1;
