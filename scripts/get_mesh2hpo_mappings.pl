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


main();

sub main {
  my @mesh_terms = ();
  my $fh = FileHandle->new('/Users/anja/Documents/G2P/pubtator/20190903/mesh_ids_linked_to_GFD_20190903', 'r');
  my $fh_out = FileHandle->new('/Users/anja/Documents/G2P/pubtator/20190903/mesh2hpo_rest', 'w');

  while (<$fh>) {
    chomp;
    push @mesh_terms, $_;  
  }
  $fh->close;
  my @array = ();
  my $count_elements = 0;
  for my $i (0 .. $#mesh_terms) {
    if ($count_elements == 50 || $i == $#mesh_terms) {
      print $count_elements, "\n";
      my $mappings = get_mesh2hpo(\@array, $fh_out);
      foreach my $mapping (@$mappings) {
        print $fh_out join("\t", @$mapping), "\n";
      }
      sleep(60);
      @array = ();
      $count_elements = 0;
    }  
    push @array, $mesh_terms[$i];
    $count_elements++;
  }
  $fh_out->close;

}

sub get_mesh2hpo {
  my $mesh_terms = shift;
  my $fh = shift;
#curl -H "Content-Type: application/json" -X POST  -d '{"ids": ["MESH:C535380", "MESH:D005099"], "mappingTarget": ["HP"], "distance":1}' htts://www.ebi.ac.uk/spot/oxo/api/search
  my $data = {
    ids => $mesh_terms,
    mappingTarget => ['HP'],
    distance => 1,
  };

  my $init_url = 'https://www.ebi.ac.uk/spot/oxo/api/search/';
  my $urls = get_next_url($init_url, $data);
  my @mappings = ();
  foreach my $url (@$urls) {
    my $http = HTTP::Tiny->new();
    my $response = $http->post_form($url, $data, 
    { 
      'Content-type' => 'application/json',
      'Accept' => 'application/json'
    },);
  if (!$response->{success}) {
    print Dumper $response;
    die "Failed!\n" unless $response->{success};
  }
    
    my $array = decode_json($response->{content});
    #"curie_id","label","mapped_curie","mapped_label","mapping_source_prefix","mapping_target_prefix","distance"

    my $results = $array->{_embedded}->{searchResults}; 
    foreach my $result (@$results) {
      next if (!$result->{mappingResponseList});
      my $query_id = $result->{queryId};
      my $curie = $result->{curie};
      my $label = $result->{label}; 
      foreach my $item (@{$result->{mappingResponseList}}) {
        my $target_prefix = $item->{targetPrefix};
        my $mapped_label = $item->{label};
        my $mapped_curie = $item->{curie};
        if ($target_prefix eq 'HP') {
          print $label, "\n";
          push @mappings, [$curie, $label, $mapped_curie, $mapped_label];
        }
      }
    }
  } 
  return \@mappings;
}


sub get_next_url {
  my $url = shift;
  my $data = shift;
  my $http = HTTP::Tiny->new();
  my $response = $http->post_form($url, $data, 
  { 
    'Content-type' => 'application/json',
    'Accept' => 'application/json'
  },);
  if (!$response->{success}) {
    print Dumper $response;
    die "Failed!\n" unless $response->{success};
  }

  my $array = decode_json($response->{content});
  my $page = $array->{page};
  if ($page) {
    my $page_number = $page->{number};
    my $total_pages = $page->{totalPages};
    my $url = $array->{_links}->{first}->{href};
    my @urls =  ();
    push @urls, $url;
   
    while ($page_number < $total_pages) {
      my $next_page_number = $page_number + 1;
      $url =~ s/page=$page_number/page=$next_page_number/;
      push @urls, $url;
      $page_number++;
    }
    return \@urls;
  }
  return [$url];
}




