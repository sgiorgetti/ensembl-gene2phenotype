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

package Bio::EnsEMBL::G2P::DBSQL::TextMiningDiseaseAdaptor;

use Bio::EnsEMBL::G2P::TextMiningDisease;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use HTTP::Tiny;
use JSON;
use Encode qw(decode encode);
use Data::Dumper;
our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $tmd = shift;  
  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO text_mining_disease (
      publication_id,
      mesh_id,
      annotated_text
    ) VALUES (?,?,?)
  });
  $sth->execute(
    $tmd->publication_id,
    $tmd->mesh_id,
    $tmd->annotated_text,
  );

  $sth->finish();

  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'text_mining_disease', 'text_mining_disease_id');
  $tmd->{text_mining_disease_id} = $dbID;
  return $tmd;
}

sub delete {
  my $self = shift;
  my $TMD = shift;
  my $dbh = $self->dbc->db_handle;
  my $sth = $dbh->prepare(q{
    DELETE FROM text_mining_disease WHERE publication_id  = ?;
  });
  $sth->execute($TMD->publication_id);
  $sth->finish();
}

sub fetch_all_by_Publication {
  my $self = shift;
  my $publication = shift;
  my $constraint = "tmd.publication_id=" . $publication->dbID;
  return $self->generic_fetch($constraint);
}

sub _fetch_all_by_Publication_REST {

}


sub store_all_by_Publication_REST {
  my $self = shift;
  my $publication = shift;

  # cleanup first
  my $tmds = $self->fetch_all_by_Publication($publication);
  foreach my $tmd (@$tmds) {
    $self->delete($tmd);
  }

  my $http = HTTP::Tiny->new();
  my $server = 'https://www.ncbi.nlm.nih.gov/CBBresearch/Lu/Demo/RESTful/tmTool.cgi/Disease/';

  my $pmid = $publication->pmid;
  my $response = $http->get($server.$pmid.'/JSON');
  die "Failed !\n" unless $response->{success};

  my $mesh_terms = {};
  my @text_mining_disease_results = ();

  if (length $response->{content}) {
    my $array = decode_json($response->{content});
    foreach my $entry (@$array) { # only 1 entry
      my $text = $entry->{text};
      foreach my $denotation (@{$entry->{denotations}}) {
        my $mesh_term = $denotation->{obj};
        my $begin = $denotation->{span}->{begin};
        my $end = $denotation->{span}->{end};
        my $annotated_text = substr $text, $begin, $end - $begin;
        $mesh_term =~ s/Disease:/MESH:/;
        if ($mesh_term) {
          $mesh_terms->{$mesh_term} = $annotated_text  
        }
      }
    }
  }
  my $phenotype_adaptor = $self->db->get_PhenotypeAdaptor;

  my @mesh_phenotypes = ();
  foreach my $name (keys %$mesh_terms) {
    my $mesh_phenotype = $phenotype_adaptor->fetch_by_stable_id_source($name, 'MESH');
    if (!$mesh_phenotype) {
      $mesh_phenotype = $phenotype_adaptor->store_mesh_phenotype($name);
    }
    push @mesh_phenotypes, $mesh_phenotype;
  }
  $phenotype_adaptor->store_mappings_to_hp(\@mesh_phenotypes);
  my %mesh_stable_id_2_phenotype_id = map {$_->stable_id => $_->dbID} @mesh_phenotypes;
  foreach my $mesh_term (keys %$mesh_terms) {
    my $phenotype_id = $mesh_stable_id_2_phenotype_id{$mesh_term};
    if ($phenotype_id) {
      my $annotated_text = $mesh_terms->{$mesh_term};
      my $publication_id = $publication->dbID; 
      my $TMD = Bio::EnsEMBL::G2P::TextMiningDisease->new(
        -publication_id => $publication->dbID,
        -mesh_id => $phenotype_id,
        -annotated_text => $annotated_text,
        -adaptor => $self,
      );
      push @text_mining_disease_results, $self->store($TMD);
    } 
  }
  return \@text_mining_disease_results;
}

sub _columns {
  my $self = shift;
  my @cols = (
    'tmd.text_mining_disease_id',
    'tmd.publication_id',
    'tmd.mesh_id',
    'tmd.annotated_text',
    'tmd.source',
    'pm.phenotype_id',
    'p.stable_id as mesh_stable_id',
    'p.name as mesh_name'
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['text_mining_disease', 'tmd'],
    ['phenotype', 'p'],
    ['phenotype_mapping', 'pm']
  );
  return @tables;
}

sub _left_join {
  my $self = shift;

  my @left_join = (
    ['phenotype', 'tmd.mesh_id = p.phenotype_id'],
    ['phenotype_mapping', 'tmd.mesh_id = pm.mesh_id'],
  );
  return @left_join;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;
  my ($text_mining_disease_id, $publication_id, $mesh_id, $annotated_text, $source, $phenotype_id, $mesh_stable_id, $mesh_name);
  $sth->bind_columns(\($text_mining_disease_id, $publication_id, $mesh_id, $annotated_text, $source, $phenotype_id, $mesh_stable_id, $mesh_name));
  my @objs;
  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::TextMiningDisease->new(
      -text_mining_disease_id => $text_mining_disease_id,
      -publication_id => $publication_id,
      -mesh_id => $mesh_id,
      -annotated_text => $annotated_text,
      -source => $source,
      -phenotype_id => $phenotype_id,
      -mesh_stable_id => $mesh_stable_id,
      -mesh_name => $mesh_name,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
