#!/software/bin/perl

use strict;
use warnings;

use Data::Dumper;
use DBI;
use FileHandle;
use Getopt::Long;
use HTTP::Tiny;
use JSON;
use Bio::EnsEMBL::Registry;
use Encode qw(decode encode);

# perl update_publication.pl -registry_file registry

my $config = {};

#GetOptions(
#  $config,
#  'registry_file=s',
#) or die "Error: Failed to parse command line arguments\n";
#die ('A registry_file file is required (--registry_file)') unless (defined($config->{registry_file}));


#my $registry = G2P::Registry->new($config->{registry_file});

my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all('/Users/anja/Documents/G2P/app/ensembl.registry');
my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle; 

main();

sub main {
  my $http = HTTP::Tiny->new();
  my $server = 'https://www.ncbi.nlm.nih.gov/CBBresearch/Lu/Demo/RESTful/tmTool.cgi/Disease/';
  
  my $pmids = get_pmids();
  foreach my $pmid (keys %$pmids) {
    my $response = $http->get($server.$pmid.'/JSON');
    die "Failed !\n" unless $response->{success};
     
    if (length $response->{content}) {
      print "PMID $pmid\n";
      my $array = decode_json($response->{content});
      my $mesh_terms = {};
      foreach my $entry (@$array) {
        print Dumper($entry), "\n";
        foreach my $denotation (@{$entry->{denotations}}) {
          my $mesh_term = $denotation->{obj};
          $mesh_term =~ s/Disease://;
          $mesh_terms->{$mesh_term} = 1;
        }
      }
      get_mesh2hpo($mesh_terms);
    }
  }
}

sub get_mesh2hpo {
  my $mesh_terms = shift;
  print "get_mesh2hpo\n";
#curl -H "Content-Type: application/json" -X POST  -d '{"ids": ["MESH:C535380", "MESH:D005099"], "mappingTarget": ["HP"], "distance":1}' htts://www.ebi.ac.uk/spot/oxo/api/search

  print join(' ', keys %$mesh_terms), "\n";
  my @ids = keys %$mesh_terms;
  my $data = {
    ids => \@ids,
    mappingTarget => ['HP'],
    distance => 1,
  };

  my $http = HTTP::Tiny->new();

  my $server = 'https://www.ebi.ac.uk/spot/oxo/api/search/';
  my $response = $http->post_form($server, $data, 
  { 
  	'Content-type' => 'application/json',
  	'Accept' => 'application/json'
  },);
 
  die "Failed!\n" unless $response->{success};

  my $array = decode_json($response->{content});
  my $results = $array->{_embedded}->{searchResults}; 
  foreach my $result (@$results) {
    next if (!$result->{mappingResponseList});
    my $query_id = $result->{queryId};
    foreach my $item (@{$result->{mappingResponseList}}) {
      my $target_prefix = $item->{targetPrefix};
      my $label = $item->{label};
      my $curie = $item->{curie};
      if ($target_prefix eq 'HP') {
        print "$query_id $label $curie\n";
      }
    }
  }
}

sub get_pmids {
  my $g2p_pmids = {};

  my $sth = $dbh->prepare(q{
    SELECT distinct p.pmid, p.publication_id from genomic_feature_disease_publication gfdp, publication p WHERE gfdp.publication_id = p.publication_id limit 20;
  }, {mysql_use_result => 1});
  $sth->execute() or die $dbh->errstr;
  my ($pmid, $publication_id);
  $sth->bind_columns(\($pmid, $publication_id));
  while ($sth->fetch) {
    $g2p_pmids->{$pmid} = $publication_id;
  }
  $sth->finish;
  return $g2p_pmids;
}

