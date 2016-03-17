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

package Bio::EnsEMBL::G2P::DBSQL::GFDPhenotypeCommentAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::GFDPhenotypeComment;

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $GFD_phenotype_comment = shift; 
  my $user = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($GFD_phenotype_comment) || !$GFD_phenotype_comment->isa('Bio::EnsEMBL::G2P::GFDPhenotypeComment')) {
    die ('Bio::EnsEMBL::G2P::GFDPhenotypeComment arg expected');
  }
  
  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die ('Bio::EnsEMBL::G2P::User arg expected');
  }
 
  my $sth = $dbh->prepare(q{
    INSERT INTO GFD_phenotype_comment (
      genomic_feature_disease_phenotype_id,
      comment_text,
      created,
      user_id
    ) VALUES (?,?,CURRENT_TIMESTAMP,?)
  });

  $sth->execute(
    $GFD_phenotype_comment->get_GFD_phenotype()->dbID(),
    $GFD_phenotype_comment->comment_text,
    $user->user_id 
  );
  $sth->finish();

  my $dbID = $dbh->last_insert_id(undef, undef, 'GFD_phenotype_comment', 'GFD_phenotype_comment_id');

  $GFD_phenotype_comment->{GFD_phenotype_comment_id} = $dbID;

  return $GFD_phenotype_comment;
}

sub delete {
  my $self = shift;
  my $GFD_phenotype_comment = shift; 
  my $user = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($GFD_phenotype_comment) || !$GFD_phenotype_comment->isa('Bio::EnsEMBL::G2P::GFDPhenotypeComment')) {
    die ('Bio::EnsEMBL::G2P::GFDPhenotypeComment arg expected');
  }
  
  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die ('Bio::EnsEMBL::G2P::User arg expected');
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO GFD_phenotype_comment_deleted (
      genomic_feature_disease_phenotype_id,
      comment_text,
      created,
      user_id,
      deleted,
      deleted_by_user_id
    ) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, ?)
  });

  $sth->execute(
    $GFD_phenotype_comment->GFD_phenotype_id,
    $GFD_phenotype_comment->comment_text,
    $GFD_phenotype_comment->created,
    $GFD_phenotype_comment->{user_id},
    $user->user_id
  );
  $sth->finish();

  $sth = $dbh->prepare(q{
    DELETE FROM GFD_phenotype_comment WHERE GFD_phenotype_comment_id = ?;
  });
  
  $sth->execute($GFD_phenotype_comment->dbID);
  $sth->finish();
}

sub fetch_by_dbID {
  my $self = shift;
  my $GFD_phenotype_comment_id = shift;
  return $self->SUPER::fetch_by_dbID($GFD_phenotype_comment_id);
}

sub fetch_all_by_GenomicFeatureDiseasePhenotype {
  my $self = shift;
  my $GFD_phenotype = shift;
  if (!ref($GFD_phenotype) || !$GFD_phenotype->isa('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePhenotype')) {
    die('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePhenotype arg expected');
  }
  my $GFD_phenotype_id = $GFD_phenotype->dbID;
  my $constraint = "gfdpc.genomic_feature_disease_phenotype_id=$GFD_phenotype_id"; 
  return $self->generic_fetch($constraint);  
}

sub _columns {
  my $self = shift;
  my @cols = (
    'gfdpc.GFD_phenotype_comment_id',
    'gfdpc.genomic_feature_disease_phenotype_id',
    'gfdpc.comment_text',
    'gfdpc.created',
    'gfdpc.user_id',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['GFD_phenotype_comment', 'gfdpc'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($GFD_phenotype_comment_id, $GFD_phenotype_id, $comment_text, $created, $user_id);
  $sth->bind_columns(\($GFD_phenotype_comment_id, $GFD_phenotype_id, $comment_text, $created, $user_id));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::GFDPhenotypeComment->new(
      -GFD_phenotype_comment_id => $GFD_phenotype_comment_id,
      -genomic_feature_disease_phenotype_id => $GFD_phenotype_id,
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
