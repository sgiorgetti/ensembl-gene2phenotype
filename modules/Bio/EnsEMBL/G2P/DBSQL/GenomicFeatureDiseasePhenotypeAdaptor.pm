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

package Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseasePhenotypeAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::G2P::GenomicFeatureDiseasePhenotype;

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $GFD_phenotype = shift;  
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_phenotype (
      genomic_feature_disease_id,
      phenotype_id
    ) VALUES (?,?);
  });
  $sth->execute(
    $GFD_phenotype->get_GenomicFeatureDisease()->dbID(),
    $GFD_phenotype->get_Phenotype()->dbID()
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease_phenotype', 'genomic_feature_disease_phenotype_id');
  $GFD_phenotype->{genomic_feature_disease_phenotype_id} = $dbID;
  return $GFD_phenotype;
}

sub delete {
  my $self = shift;
  my $GFDP = shift; 
  my $user = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($GFDP) || !$GFDP->isa('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePhenotype')) {
    die ('Bio::EnsEMBL::G2P::GenomicFeatureDiseasePhenotype arg expected');
  }
  
  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die ('Bio::EnsEMBL::G2P::User arg expected');
  }

  my $GFDPhenotypeCommentAdaptor = $self->db->get_GFDPhenotypeCommentAdaptor;
  foreach my $GFDPhenotypeComment (@{$GFDP->get_all_GFDPhenotypeComments}) {
    $GFDPhenotypeCommentAdaptor->delete($GFDPhenotypeComment, $user);
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_phenotype_deleted SELECT * FROM genomic_feature_disease_phenotype WHERE genomic_feature_disease_phenotype_id = ?;
  });
  $sth->execute($GFDP->dbID);

  $sth = $dbh->prepare(q{
    DELETE FROM genomic_feature_disease_phenotype WHERE genomic_feature_disease_phenotype_id = ?;
  });

  $sth->execute($GFDP->dbID);
  $sth->finish();
}

sub fetch_by_dbID {
  my $self = shift;
  my $dbID = shift;
  return $self->SUPER::fetch_by_dbID($dbID);
}

sub fetch_by_GFD_id_phenotype_id {
  my $self = shift;
  my $GFD_id = shift;
  my $phenotype_id = shift;
  my $constraint = "gfdp.genomic_feature_disease_id=$GFD_id AND gfdp.phenotype_id=$phenotype_id";
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
    'gfdp.genomic_feature_disease_phenotype_id',
    'gfdp.genomic_feature_disease_id',
    'gfdp.phenotype_id',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['genomic_feature_disease_phenotype', 'gfdp'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($GFD_phenotype_id, $genomic_feature_disease_id, $phenotype_id);
  $sth->bind_columns(\($GFD_phenotype_id, $genomic_feature_disease_id, $phenotype_id));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::GenomicFeatureDiseasePhenotype->new(
      -genomic_feature_disease_phenotype_id => $GFD_phenotype_id,
      -genomic_feature_disease_id => $genomic_feature_disease_id,
      -phenotype_id => $phenotype_id,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
