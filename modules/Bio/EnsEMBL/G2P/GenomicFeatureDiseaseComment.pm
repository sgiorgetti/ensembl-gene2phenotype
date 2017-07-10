use strict;
use warnings;

package Bio::EnsEMBL::G2P::GenomicFeatureDiseaseComment;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($genomic_feature_disease_comment_id, $genomic_feature_disease_id, $comment_text, $created, $user_id, $adaptor) =
    rearrange(['genomic_feature_disease_comment_id', 'genomic_feature_disease_id', 'comment_text', 'created', 'user_id', 'adaptor'], @_);

  my $self = bless {
    'genomic_feature_disease_comment_id' => $genomic_feature_disease_comment_id,
    'genomic_feature_disease_id' => $genomic_feature_disease_id,
    'comment_text' => $comment_text,
    'created' => $created,
    'user_id' => $user_id,
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{genomic_feature_disease_comment_id};
}

sub GFD_id {
  my $self = shift;
  $self->{'genomic_feature_disease_id'} = shift if ( @_ );
  return $self->{'genomic_feature_disease_id'};
}

sub comment_text {
  my $self = shift;
  $self->{'comment_text'} = shift if ( @_ );
  return $self->{'comment_text'};
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

sub get_GenomicFeatureDisease {
  my $self = shift;
  my $gfd_adaptor = $self->{adaptor}->db->get_GenomicFeatureDiseaseAdaptor;
  return $gfd_adaptor->fetch_by_dbID($self->{genomic_feature_disease_id});
}

1;
