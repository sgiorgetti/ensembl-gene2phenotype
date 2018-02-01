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

package Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseCommentAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::GenomicFeatureDiseaseComment;

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $genomic_feature_disease_comment = shift; 
  my $user = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($genomic_feature_disease_comment) || !$genomic_feature_disease_comment->isa('Bio::EnsEMBL::G2P::GenomicFeatureDiseaseComment')) {
    die ('Bio::EnsEMBL::G2P::GenomicFeatureDiseaseComment arg expected');
  }
  
  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die ('Bio::EnsEMBL::G2P::User arg expected');
  }
 
  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_comment (
      genomic_feature_disease_id,
      comment_text,
      created,
      user_id
    ) VALUES (?,?,CURRENT_TIMESTAMP,?)
  });

  $sth->execute(
    $genomic_feature_disease_comment->get_GenomicFeatureDisease()->dbID(),
    $genomic_feature_disease_comment->comment_text,
    $user->user_id 
  );
  $sth->finish();

  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease_comment', 'genomic_feature_disease_comment_id');

  $genomic_feature_disease_comment->{genomic_feature_disease_comment_id} = $dbID;

  return $genomic_feature_disease_comment;
}

sub delete {
  my $self = shift;
  my $GFD_comment = shift; 
  my $user = shift;
  my $dbh = $self->dbc->db_handle;
  if (!ref($GFD_comment) || !$GFD_comment->isa('Bio::EnsEMBL::G2P::GenomicFeatureDiseaseComment')) {
    die ('Bio::EnsEMBL::G2P::GenomicFeatureDiseaseComment arg expected');
  }
  
  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die ('Bio::EnsEMBL::G2P::User arg expected');
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO GFD_comment_deleted (
      genomic_feature_disease_id,
      comment_text,
      created,
      user_id,
      deleted,
      deleted_by_user_id
    ) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, ?)
  });

  $sth->execute(
    $GFD_comment->GFD_id,
    $GFD_comment->comment_text,
    $GFD_comment->created,
    $GFD_comment->{user_id},
    $user->user_id
  );
  $sth->finish();

  $sth = $dbh->prepare(q{
    DELETE FROM genomic_feature_disease_comment WHERE genomic_feature_disease_comment_id = ?;
  });
  
  $sth->execute($GFD_comment->dbID);
  $sth->finish();
}

sub fetch_by_dbID {
  my $self = shift;
  my $GFD_comment_id = shift;
  return $self->SUPER::fetch_by_dbID($GFD_comment_id);
}

sub fetch_all_by_GenomicFeatureDisease {
  my $self = shift;
  my $GFD = shift;
  if (!ref($GFD) || !$GFD->isa('Bio::EnsEMBL::G2P::GenomicFeatureDisease')) {
    die('Bio::EnsEMBL::G2P::GenomicFeatureDisease arg expected');
  }
  my $GFD_id = $GFD->dbID;
  my $constraint = "gfdc.genomic_feature_disease_id=$GFD_id"; 
  return $self->generic_fetch($constraint);  
}

sub _columns {
  my $self = shift;
  my @cols = (
    'gfdc.genomic_feature_disease_comment_id',
    'gfdc.genomic_feature_disease_id',
    'gfdc.comment_text',
    'gfdc.created',
    'gfdc.user_id',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['genomic_feature_disease_comment', 'gfdc'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($GFD_comment_id, $GFD_id, $comment_text, $created, $user_id);
  $sth->bind_columns(\($GFD_comment_id, $GFD_id, $comment_text, $created, $user_id));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseComment->new(
      -genomic_feature_disease_comment_id => $GFD_comment_id,
      -genomic_feature_disease_id => $GFD_id,
      -comment_text => $comment_text,
      -created => $created,
      -user_id => $user_id,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
