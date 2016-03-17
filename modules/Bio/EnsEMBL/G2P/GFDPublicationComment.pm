use strict;
use warnings;

package Bio::EnsEMBL::G2P::GFDPublicationComment;
use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($GFD_publication_comment_id, $GFD_publication_id, $comment_text, $created, $user_id, $adaptor) =
    rearrange(['GFD_publication_comment_id', 'genomic_feature_disease_publication_id', 'comment_text', 'created', 'user_id', 'adaptor'], @_);

  my $self = bless {
    'GFD_publication_comment_id' => $GFD_publication_comment_id,
    'genomic_feature_disease_publication_id' => $GFD_publication_id,
    'comment_text' => $comment_text,
    'created' => $created,
    'user_id' => $user_id,
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{GFD_publication_comment_id};
}

sub comment_text {
  my $self = shift;
  $self->{'comment_text'} = shift if ( @_ );
  return $self->{'comment_text'};
}

sub GFD_publication_id {
  my $self = shift;
  $self->{'genomic_feature_disease_publication_id'} = shift if ( @_ );
  return $self->{'genomic_feature_disease_publication_id'};
}

sub created {
  my $self = shift;
  $self->{'created'} = shift if ( @_ );
  return $self->{'created'};
}

sub get_User {
  my $self = shift;
  my $user_adaptor = $self->{adaptor}->db->get_UserAdaptor;
  return $user_adaptor->fetch_by_dbID($self->{user_id});
}

sub get_GFD_publication {
  my $self = shift;
  my $GFD_publication_adaptor = $self->{adaptor}->db->get_GenomicFeatureDiseasePublicationAdaptor;
  return $GFD_publication_adaptor->fetch_by_dbID($self->GFD_publication_id);
}

1;
