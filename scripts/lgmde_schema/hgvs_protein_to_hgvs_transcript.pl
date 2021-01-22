# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use DBI;
use Getopt::Long;
use FileHandle;

use Bio::EnsEMBL::G2P::AlleleFeature;
use Bio::EnsEMBL::G2P::TranscriptAllele;

use REST::Client;
use JSON;
use Data::Dumper;
my $config = {};

GetOptions(
  $config,
  'registry_file=s',
  'input_hgvsp_ids=s',
) or die "Error: Failed to parse command line arguments\n";


my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);

my $species = 'human';
my $allele_feature_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'AlleleFeature');
my $transcript_allele_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'TranscriptAllele');
my $gene_feature_adaptor = $registry->get_adaptor($species, 'gene2phenotype', 'GeneFeature');

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle;

$dbh->do(qq{TRUNCATE TABLE allele_feature;}) or die $dbh->errstr;
$dbh->do(qq{TRUNCATE TABLE transcript_allele;}) or die $dbh->errstr;

load_alleles();
sub load_alleles {
  my $fh = FileHandle->new($config->{input_hgvsp_ids}, 'r');
  while (<$fh>) {
    chomp;
    my $input_id = $_; 
    _load($input_id);
  }
  $fh->close();
}

sub _load {
  my $input_id = shift;

  my $client = REST::Client->new();
  my $ensembl_rest_host = 'http://rest.ensembl.org';
  $client->setHost($ensembl_rest_host);
  my $headers = {Accept => 'application/json'};
  my ($gene, $input_hgvsp) = split(':', $input_id);
  my $gene_feature = $gene_feature_adaptor->fetch_by_gene_symbol($gene);
  $client->GET(
    '/variant_recoder/human/' . $input_id . '?fields=hgvsg',
    $headers
  );
  my $response = from_json($client->responseContent);
  if (ref($response) eq 'HASH' && $response->{error}) {
    print "Couldn't get mappings for $input_id: " . $response->{error} . "\n";
    return;
  }
  my @mappings = grep {$_ !~ /^LRG/} @{$response->[0]->{'hgvsg'}};
  my $content = to_json({hgvs_notations => [@mappings]});

  $client->POST(
    '/vep/human/hgvs?mane=1&hgvs=1&CADD=1&shift_3prime=1&shift_genomic=1&transcript_version=1&tsl=1&appris=1', $content, $headers
  );

  $response = from_json($client->responseContent);

  foreach my $hash (@{$response}) {
    foreach my $tc (@{$hash->{'transcript_consequences'}}) {
      my $hgvsp = $tc->{hgvsp};
      if (defined $hgvsp && $hgvsp =~ m/$input_hgvsp/) {
        my $seq_region_name = $hash->{seq_region_name};
        my $seq_region_start = $hash->{start};
        my $seq_region_end = $hash->{end};
        my ($ref_allele, $alt_allele) = split('/', $hash->{allele_string});
        my $hgvs_genomic = $hash->{input}; 
        my $allele_feature = $allele_feature_adaptor->fetch_by_name_and_hgvs_genomic($input_id, $hgvs_genomic);
        if (! defined $allele_feature) { 
          $allele_feature = Bio::EnsEMBL::G2P::AlleleFeature->new(
            -seq_region_name => $seq_region_name,
            -seq_region_start => $seq_region_start,
            -seq_region_end => $seq_region_end,
            -name => $input_id,
            -ref_allele => $ref_allele,
            -alt_allele => $alt_allele,
            -hgvs_genomic => $hgvs_genomic,
            -adaptor => $allele_feature_adaptor,
          );
          $allele_feature = $allele_feature_adaptor->store($allele_feature);
        }
        my $allele_feature_id = $allele_feature->dbID;

        if (!defined $allele_feature_id) {
          print "couldn't fetch allele feature for $input_id, $hgvs_genomic\n";
          next;
        }
        my $transcript_id = $tc->{transcript_id};
        my $transcript_allele = $transcript_allele_adaptor->fetch_by_allele_feature_id_and_transcript_stable_id($allele_feature_id, $transcript_id);
        if (! defined $transcript_allele) {
          $transcript_allele = Bio::EnsEMBL::G2P::TranscriptAllele->new(
            -allele_feature_id => $allele_feature_id,
            -transcript_stable_id => $tc->{transcript_id},
            -gene_feature_id => $gene_feature->dbID,
            -consequence_types => join(',', sort @{$tc->{consequence_terms}}),
            -cds_start => $tc->{cds_start},
            -cds_end => $tc->{cds_end},
            -cdna_start => $tc->{cdna_start},
            -cdna_end => $tc->{cdna_end},
            -translation_start => $tc->{protein_start},
            -translation_end => $tc->{protein_end},
            -codon_allele_string => $tc->{codons},
            -pep_allele_string => $tc->{amino_acids},
            -hgvs_transcript => $tc->{hgvsc},
            -hgvs_protein => $tc->{hgvsp},
            -cadd => $tc->{cadd_phred},
            -sift_prediction => $tc->{sift_prediction},
            -polyphen_prediction => $tc->{polyphen_prediction},
            -appris => $tc->{appris},
            -tsl => $tc->{tsl},
            -mane => $tc->{mane},
            -adaptor => $transcript_allele_adaptor,
          );
          $transcript_allele_adaptor->store($transcript_allele);
        } 
      }
    }
  }
}
