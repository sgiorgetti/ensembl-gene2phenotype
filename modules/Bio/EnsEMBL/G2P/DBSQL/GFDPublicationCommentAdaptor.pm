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

package Bio::EnsEMBL::G2P::DBSQL::GFDPublicationCommentAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::GFDPublicationComment;

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $GFD_publication_comment = shift; 
  my $user = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($GFD_publication_comment) || !$GFD_publication_comment->isa('Bio::EnsEMBL::G2P::GFDPublicationComment')) {
    die ('Bio::EnsEMBL::G2P::GFDPublicationComment arg expected');
  }
  
  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die ('Bio::EnsEMBL::G2P::User arg expected');
  }
 
  my $sth = $dbh->prepare(q{
    INSERT INTO GFD_publication_comment (
      GFD_publication_id,
      comment_text,
      created,
      user_id
    ) VALUES (?,?,CURRENT_TIMESTAMP,?)
  });

  $sth->execute(
    $GFD_publication_comment->get_GFD_publication()->dbID(),
    $GFD_publication_comment->comment_text,
    $user->user_id 
  );
  $sth->finish();

  my $dbID = $dbh->last_insert_id(undef, undef, 'GFD_publication_comment', 'GFD_publication_comment_id');

  $GFD_publication_comment->{GFD_publication_comment_id} = $dbID;

  return $GFD_publication_comment;
}

sub delete {
  my $self = shift;
  my $GFD_publication_comment = shift; 
  my $user = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($GFD_publication_comment) || !$GFD_publication_comment->isa('Bio::EnsEMBL::G2P::GFDPublicationComment')) {
    die ('Bio::EnsEMBL::G2P::GFDPublicationComment arg expected');
  }

  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die ('Bio::EnsEMBL::G2P::User arg expected');
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO GFD_publication_comment_deleted (
      GFD_publication_id,
      comment_text,
      created,
      user_id,
      deleted,
      deleted_by_user_id
    ) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, ?)
  });

  $sth->execute(
    $GFD_publication_comment->GFD_publication_id,
    $GFD_publication_comment->comment_text,
    $GFD_publication_comment->created,
    $GFD_publication_comment->{user_id},
    $user->user_id
  );
  $sth->finish();

  $sth = $dbh->prepare(q{
    DELETE FROM GFD_publication_comment WHERE GFD_publication_comment_id = ?;
  });
  
  $sth->execute($GFD_publication_comment->dbID);
  $sth->finish();
}

sub fetch_by_dbID {
  my $self = shift;
  my $GFD_publication_comment_id = shift;
  return $self->SUPER::fetch_by_dbID($GFD_publication_comment_id);
}

sub fetch_all_by_GenomicFeatureDiseasePublication {
  my $self = shift;
  my $GFD_publication = shift;
  if (!ref($GFD_publication) || !$GFD_publication->isa('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication')) {
    die('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePublication arg expected');
  }
  my $GFD_publication_id = $GFD_publication->dbID;
  my $constraint = "gfdpc.GFD_publication_id=$GFD_publication_id"; 
  return $self->generic_fetch($constraint);  
}

sub _columns {
  my $self = shift;
  my @cols = (
    'gfdpc.GFD_publication_comment_id',
    'gfdpc.GFD_publication_id',
    'gfdpc.comment_text',
    'gfdpc.created',
    'gfdpc.user_id',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['GFD_publication_comment', 'gfdpc'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($GFD_publication_comment_id, $GFD_publication_id, $comment_text, $created, $user_id);
  $sth->bind_columns(\($GFD_publication_comment_id, $GFD_publication_id, $comment_text, $created, $user_id));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::GFDPublicationComment->new(
      -GFD_publication_comment_id => $GFD_publication_comment_id,
      -GFD_publication_id => $GFD_publication_id,
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
