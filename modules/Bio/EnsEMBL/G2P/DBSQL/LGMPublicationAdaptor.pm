=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2020] EMBL-European Bioinformatics Institute
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

package Bio::EnsEMBL::G2P::DBSQL::LGMPublicationAdaptor;

use Bio::EnsEMBL::G2P::LGMPublication;
use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $lgm_publication = shift;

  if (!ref($lgm_publication) || !$lgm_publication->isa('Bio::EnsEMBL::G2P::LGMPublication')) {
    die('Bio::EnsEMBL::G2P::LGMPublication arg expected');
  }

  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO LGM_publication(
      locus_genotype_mechanism_id,
      publication_id,
      user_id,
      created
    ) VALUES (?, ?, ?, CURRENT_TIMESTAMP)
  });

  $sth->execute(
    $lgm_publication->locus_genotype_mechanism_id,
    $lgm_publication->publication_id,
    $lgm_publication->user_id
  );

  $sth->finish();
  
  my $dbID = $dbh->last_insert_id(undef, undef, 'LGM_publication', 'LGM_publication_id'); 
  $lgm_publication->{LGM_publication_id} = $dbID;

  return $lgm_publication;
}

sub fetch_all {
  my $self = shift;
  return $self->generic_fetch();
}

sub fetch_by_LocusGenotypeMechanism_Publication {
  my $self = shift;
  my $locus_genotype_mechanism = shift;
  my $publication = shift;
  my $locus_genotype_mechanism_id = $locus_genotype_mechanism->dbID;
  my $publication_id = $publication->dbID;
  my $constraint = "locus_genotype_mechanism_id=$locus_genotype_mechanism_id AND publication_id=$publication_id;";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_all_by_LocusGenotypeMechanism {
  my $self = shift;
  my $locus_genotype_mechanism = shift;
  my $locus_genotype_mechanism_id = $locus_genotype_mechanism->dbID;
  my $constraint = "locus_genotype_mechanism_id=$locus_genotype_mechanism_id;";
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'LGM_publication_id',
    'locus_genotype_mechanism_id',
    'publication_id',
    'user_id',
    'created',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['LGM_publication'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;
  my ($LGM_publication_id, $locus_genotype_mechanism_id, $publication_id, $user_id, $created);
  $sth->bind_columns(\($LGM_publication_id, $locus_genotype_mechanism_id, $publication_id, $user_id, $created));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::LGMPublication->new(
      -LGM_publication_id => $LGM_publication_id,
      -locus_genotype_mechanism_id => $locus_genotype_mechanism_id,
      -publication_id => $publication_id,
      -user_id => $user_id,
      -created => $created,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
