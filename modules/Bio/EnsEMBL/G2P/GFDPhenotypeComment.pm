use strict;
use warnings;

package Bio::EnsEMBL::G2P::GFDPhenotypeComment;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($GFD_phenotype_comment_id, $GFD_phenotype_id, $comment_text, $created, $user_id, $adaptor) =
    rearrange(['GFD_phenotype_comment_id', 'genomic_feature_disease_phenotype_id', 'comment_text', 'created', 'user_id', 'adaptor'], @_);

  my $self = bless {
    'GFD_phenotype_comment_id' => $GFD_phenotype_comment_id,
    'genomic_feature_disease_phenotype_id' => $GFD_phenotype_id,
    'comment_text' => $comment_text,
    'created' => $created,
    'user_id' => $user_id,
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  return $self->{GFD_phenotype_comment_id};
}

sub comment_text {
  my $self = shift;
  $self->{'comment_text'} = shift if ( @_ );
  return $self->{'comment_text'};
}

sub GFD_phenotype_id {
  my $self = shift;
  $self->{'genomic_feature_disease_phenotype_id'} = shift if ( @_ );
  return $self->{'genomic_feature_disease_phenotype_id'};
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

sub get_GFD_phenotype {
  my $self = shift;
  my $GFD_phenotype_adaptor = $self->{adaptor}->db->get_GenomicFeatureDiseasePhenotypeAdaptor;
  return $GFD_phenotype_adaptor->fetch_by_dbID($self->GFD_phenotype_id);
}

1;
