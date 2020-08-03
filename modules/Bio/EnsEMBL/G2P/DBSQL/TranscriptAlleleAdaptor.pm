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

package Bio::EnsEMBL::G2P::DBSQL::TranscriptAlleleAdaptor;

use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;

use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my ($self, $transcript_allele) = @_;
  my $dbh = $self->dbc->db_handle;
  my $sth = $dbh->prepare(q{
    INSERT INTO transcript_allele (
      allele_feature_id,
      gene_feature_id,
      transcript_stable_id,
      consequence_types,
      cds_start,
      cds_end,
      cdna_start,
      cdna_end,
      translation_start,
      translation_end,
      codon_allele_string,
      pep_allele_string,
      hgvs_transcript,
      hgvs_protein,
      cadd,
      sift_prediction,
      polyphen_prediction,
      appris,
      tsl,
      mane
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
  });

  $sth->execute(
    $transcript_allele->allele_feature_id,
    $transcript_allele->gene_feature_id,
    $transcript_allele->transcript_stable_id,
    $transcript_allele->consequence_types,
    $transcript_allele->cds_start,
    $transcript_allele->cds_end,
    $transcript_allele->cdna_start,
    $transcript_allele->cdna_end,
    $transcript_allele->translation_start,
    $transcript_allele->translation_end,
    $transcript_allele->codon_allele_string,
    $transcript_allele->pep_allele_string,
    $transcript_allele->hgvs_transcript,
    $transcript_allele->hgvs_protein,
    $transcript_allele->cadd,
    $transcript_allele->sift_prediction,
    $transcript_allele->polyphen_prediction,
    $transcript_allele->appris,
    $transcript_allele->tsl,
    $transcript_allele->mane
  );

  $sth->finish;

  my $dbID = $dbh->last_insert_id(undef, undef, 'transcript_allele', 'transcript_allele_id');
  $transcript_allele->{dbID}    = $dbID;
  $transcript_allele->{adaptor} = $self;
}

sub fetch_all {
  my $self = shift;
  return $self->generic_fetch();
}

sub fetch_by_dbID {
  my $self = shift;
  my $transcript_allele_id = shift;
  return $self->SUPER::fetch_by_dbID($transcript_allele_id);
}

sub fetch_by_allele_feature_id_and_transcript_stable_id {
  my ($self, $allele_feature_id, $transcript_stable_id) = @_;
  my $constraint = "ta.allele_feature_id=$allele_feature_id AND ta.transcript_stable_id='$transcript_stable_id';";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub _columns {
  my $self = shift;
  my @cols = (
    'ta.transcript_allele_id',
    'ta.allele_feature_id',
    'ta.gene_feature_id',
    'ta.transcript_stable_id',
    'ta.consequence_types',
    'ta.cds_start',
    'ta.cds_end',
    'ta.cdna_start',
    'ta.cdna_end',
    'ta.translation_start',
    'ta.translation_end',
    'ta.codon_allele_string',
    'ta.pep_allele_string',
    'ta.hgvs_transcript',
    'ta.hgvs_protein',
    'ta.cadd',
    'ta.sift_prediction',
    'ta.polyphen_prediction',
    'ta.appris',
    'ta.tsl',
    'ta.mane'
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['transcript_allele', 'ta'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($transcript_allele_id, $allele_feature_id, $gene_feature_id, $transcript_stable_id, $consequence_types, $cds_start, $cds_end, $cdna_start, $cdna_end, $translation_start, $translation_end, $codon_allele_string, $pep_allele_string, $hgvs_transcript, $hgvs_protein, $cadd, $sift_prediction, $polyphen_prediction, $appris, $tsl, $mane); 
  $sth->bind_columns(\($transcript_allele_id, $allele_feature_id, $gene_feature_id, $transcript_stable_id, $consequence_types, $cds_start, $cds_end, $cdna_start, $cdna_end, $translation_start, $translation_end, $codon_allele_string, $pep_allele_string, $hgvs_transcript, $hgvs_protein, $cadd, $sift_prediction, $polyphen_prediction, $appris, $tsl, $mane)); 

  my @objs;
  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::TranscriptAllele->new(
      -transcript_allele_id => $transcript_allele_id,
      -allele_feature_id => $allele_feature_id,
      -gene_feature_id => $gene_feature_id,
      -transcript_stable_id => $transcript_stable_id,
      -consequence_types => $consequence_types,
      -cds_start => $cds_start,
      -cds_end => $cds_end,
      -cdna_start => $cdna_start,
      -cdna_end => $cdna_end,
      -translation_start => $translation_start,
      -translation_end => $translation_end,
      -codon_allele_string => $codon_allele_string,
      -pep_allele_string => $pep_allele_string,
      -hgvs_transcript => $hgvs_transcript,
      -hgvs_protein => $hgvs_protein,
      -cadd => $cadd,
      -sift_prediction => $sift_prediction,
      -polyphen_prediction => $polyphen_prediction,
      -appris => $appris,
      -tsl => $tsl,
      -mane => $mane,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}


1;
