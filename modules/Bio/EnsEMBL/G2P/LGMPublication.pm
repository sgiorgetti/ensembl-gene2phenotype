use strict;
use warnings;

package Bio::EnsEMBL::G2P::LGMPublication;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($LGM_publication_id, $locus_genotype_mechanism_id, $publication_id, $user_id, $created, $adaptor) =
    rearrange(['LGM_publication_id', 'locus_genotype_mechanism_id', 'publication_id', 'user_id', 'created', 'adaptor'], @_);

  my $self = bless {
    'dbID' => $LGM_publication_id,
    'LGM_publication_id' => $LGM_publication_id,
    'locus_genotype_mechanism_id' => $locus_genotype_mechanism_id,
    'publication_id' => $publication_id,
    'user_id' => $user_id,
    'created' => $created,
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  $self->{dbID} = shift if @_;
  return $self->{dbID};
}

sub LGM_publication_id {
  my $self = shift;
  $self->{LGM_publication_id} = shift if @_;
  return $self->{LGM_publication_id};
}

sub locus_genotype_mechanism_id {
  my $self = shift;
  $self->{locus_genotype_mechanism_id} = shift if @_;
  return $self->{locus_genotype_mechanism_id};
}

sub publication_id {
  my $self = shift;
  $self->{publication_id} = shift if @_;
  return $self->{publication_id};
}

sub user_id {
  my $self = shift;
  $self->{user_id} = shift if @_;
  return $self->{user_id};
}

sub created {
  my $self = shift;
  $self->{created} = shift if @_;
  return $self->{created};
}

sub get_Publication {
  my $self = shift;
  my $publication_adaptor = $self->{adaptor}->db->get_PublicationAdaptor;
  return $publication_adaptor->fetch_by_dbID($self->publication_id);
}

sub get_User {
  my $self = shift;
  my $user_adaptor = $self->{adaptor}->db->get_UserAdaptor;
  return $user_adaptor->fetch_by_dbID($self->user_id);
}




1;
