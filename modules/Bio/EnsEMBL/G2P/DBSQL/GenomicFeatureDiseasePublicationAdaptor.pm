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

package Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseasePublicationAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication;

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

=head2 store

  Arg [1]    : Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication $GFD_publication
  Example    : $GFD_publication = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication->new(...);
               $GFD_publication = $GFD_publication_adaptor->store($GFD_publication);
  Description: This stores a GenomicFeatureDiseasePublication in the database.
  Returntype : Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication
  Exceptions : - Throw error if $GFD_publication is not a
                 Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication
  Caller     :
  Status     : Stable

=cut

sub store {
  my $self = shift;
  my $GFD_publication = shift;  

  if (!ref($GFD_publication) || !$GFD_publication->isa('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication')) {
    die('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication arg expected');
  }

  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_publication (
      genomic_feature_disease_id,
      publication_id
    ) VALUES (?,?);
  });
  $sth->execute(
    $GFD_publication->get_GenomicFeatureDisease()->dbID(),
    $GFD_publication->get_Publication()->dbID()
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease_publication', 'genomic_feature_disease_publication_id');
  $GFD_publication->{genomic_feature_disease_publication_id} = $dbID;
  return $GFD_publication;
}

sub delete {
  my $self = shift;
  my $GFDP = shift; 
  my $user = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($GFDP) || !$GFDP->isa('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication')) {
    die ('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication arg expected');
  }
  
  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die ('Bio::EnsEMBL::G2P::User arg expected');
  }

  my $GFDPublicationCommentAdaptor = $self->db->get_GFDPublicationCommentAdaptor;
  foreach my $GFDPublicationComment (@{$GFDP->get_all_GFDPublicationComments}) {
    $GFDPublicationCommentAdaptor->delete($GFDPublicationComment, $user);
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_publication_deleted SELECT * FROM genomic_feature_disease_publication WHERE genomic_feature_disease_publication_id = ?;
  }); 
  $sth->execute($GFDP->dbID);

  $sth = $dbh->prepare(q{
    DELETE FROM genomic_feature_disease_publication WHERE genomic_feature_disease_publication_id = ?;
  });

  $sth->execute($GFDP->dbID);
  $sth->finish();
}

sub fetch_by_dbID {
  my $self = shift;
  my $dbID = shift;
  return $self->SUPER::fetch_by_dbID($dbID);
}

sub fetch_by_GFD_id_publication_id {
  my $self = shift;
  my $GFD_id = shift;
  my $publication_id = shift;
  my $constraint = "gfdp.genomic_feature_disease_id=$GFD_id AND gfdp.publication_id=$publication_id";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_all_by_GenomicFeatureDisease {
  my $self = shift;
  my $GFD = shift;
  if (!ref($GFD) || !$GFD->isa('Bio::EnsEMBL::G2P::GenomicFeatureDisease')) {
    die('Bio::EnsEMBL::G2P::GenomicFeatureDisease arg expected');
  }
  my $GFD_id = $GFD->dbID;
  my $constraint = "gfdp.genomic_feature_disease_id=$GFD_id"; 
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'gfdp.genomic_feature_disease_publication_id',
    'gfdp.genomic_feature_disease_id',
    'gfdp.publication_id',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['genomic_feature_disease_publication', 'gfdp'],
  );
  return @tables;
}

=head2 _objs_from_sth

  Arg [1]    : StatementHandle $sth
  Description: Responsible for the creation of GenomicFeatureDiseasePublications
  Returntype : listref of Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication
  Exceptions : None
  Caller     : Internal
  Status     : Stable

=cut

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($GFD_publication_id, $genomic_feature_disease_id, $publication_id);
  $sth->bind_columns(\($GFD_publication_id, $genomic_feature_disease_id, $publication_id));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication->new(
      -genomic_feature_disease_publication_id => $GFD_publication_id,
      -genomic_feature_disease_id => $genomic_feature_disease_id,
      -publication_id => $publication_id,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;

