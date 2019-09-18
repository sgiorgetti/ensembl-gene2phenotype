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

GetOptions(
  $config,
  'registry_file=s',
) or die "Error: Failed to parse command line arguments\n";
die ('A registry_file file is required (--registry_file)') unless (defined($config->{registry_file}));


my $registry = 'Bio::EnsEMBL::Registry';
my $registry_file = $config->{registry_file};
$registry->load_all($registry_file);

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle; 

main();

sub main {
  my $query_by_pmid = 'https://www.ebi.ac.uk/europepmc/webservices/rest/search/query=ext_id:';
  my $query_by_title = 'https://www.ebi.ac.uk/europepmc/webservices/rest/search/query=';    

  my $publication_attribs = get_publication_attribs();
  foreach my $publication_id (keys %$publication_attribs) {
    my $pmid_attrib = $publication_attribs->{$publication_id}->{pmid}; 
    my $title_attrib = $publication_attribs->{$publication_id}->{title};
    my $source_attrib = $publication_attribs->{$publication_id}->{source};
    my $response;
    if (!$pmid_attrib && $title_attrib) {
      $response = run_query($query_by_title.$title_attrib);
    }
    if ($pmid_attrib && (!$title_attrib || !$source_attrib)) {
      $response = run_query($query_by_pmid.$pmid_attrib);
    }
    my $results = parse_publication_attribs($response);
    foreach my $result (@$results) {
      my ($pmid, $title, $source) = @{$result};
      if ((!$title_attrib || !$source_attrib) && $title && $source) {
        if ($pmid eq $pmid_attrib) {
          print STDERR "Update Title and or Source $pmid, $title, $source\n";
          $dbh->do(qq{UPDATE publication SET title='$title' WHERE publication_id=$publication_id;}) or die $dbh->errstr;  
          $dbh->do(qq{UPDATE publication SET source='$source' WHERE publication_id=$publication_id;}) or die $dbh->errstr;  
        }
      }
      if (!$pmid_attrib && $pmid) {
        if ($title eq $title_attrib) {
          print STDERR "Update PMID $pmid, $title, $source\n";
          $dbh->do(qq{UPDATE publication SET pmid='$pmid' WHERE publication_id=$publication_id;}) or die $dbh->errstr;  
        }
      }
    }
  }
}

sub run_query {
  my $query = shift;
  $query =~ s/\s+/+/g;
  $query =~ s/\?/%3F/g;

  my $http = HTTP::Tiny->new();
  my $response = $http->get($query.'&format=json');
  die "Failed !\n" unless $response->{success};
  return $response;
}

sub parse_publication_attribs {
  my $response = shift;
  my @results = ();
  if (length $response->{content}) {
    my $hash = decode_json($response->{content});
    foreach my $result (@{$hash->{resultList}->{result}}) {
      my ($pmid, $title, $source) = (undef, undef, undef);
      $pmid = $result->{pmid};
      $title = $result->{title};
      if ($title) {
        $title =~ s/'/\\'/g;
        $title = encode('utf8', $title);
      }
      my $journalTitle = $result->{journalTitle};
      my $journalVolume = $result->{journalVolume};
      my $pageInfo = $result->{pageInfo};
      my $pubYear = $result->{pubYear}; 
      $source .= "$journalTitle. " if ($journalTitle);
      $source .= "$journalVolume: " if ($journalVolume);
      $source .= "$pageInfo, " if ($pageInfo);
      $source .= "$pubYear." if ($pubYear);
      if ($source) {
        $source =~ s/'/\\'/g;
        $source = encode('utf8', $source);
      }
      $pmid = encode('utf8', $pmid);
      push  @results, [$pmid, $title, $source];
    }
  }

  return \@results;
}

sub get_publication_attribs {
  my $pmids = {};
  my $sth = $dbh->prepare(q{
    SELECT publication_id, pmid, title, source FROM publication;
  }); 
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  my ($publication_id, $pmid, $title, $source);
  $sth->bind_columns(\($publication_id, $pmid, $title, $source));
  while (my $row = $sth->fetchrow_arrayref()) {
    $pmids->{$publication_id}->{pmid} = $pmid;
    $pmids->{$publication_id}->{title} = $title;
    $pmids->{$publication_id}->{source} = $source;
  } 
  $sth->finish(); 
  return $pmids;
}


=begin
{
  'resultList' => {
    'result' => [
      {
        'hasLabsLinks' => 'N',
        'source' => 'MED',
        'dbCrossReferenceList' => {
          'dbName' => [
            'EMBL',
            'OMIM'
          ]
        },
        'issue' => '1',
        'hasReferences' => 'Y',
        'pubYear' => '1984',
        'hasDbCrossReferences' => 'Y',
        'luceneScore' => '107.8565',
        'id' => '6204922',
        'authorString' => 'Snyder FF, Chudley AE, MacLeod PM, Carter RJ, Fung E, Lowe JK.',
        'hasTMAccessionNumbers' => 'N',
        'doi' => '10.1007/bf00270552',
        'pageInfo' => '18-22',
        'journalIssn' => '0340-6717',
        'pubType' => 'journal article; case reports; research support, non-u.s. gov\'t',
        'inEPMC' => 'N',
        'inPMC' => 'N',
        'journalTitle' => 'Hum Genet',
        'journalVolume' => '67',
        'title' => 'Partial deficiency of hypoxanthine-guanine phosphoribosyltransferase with reduced affinity for PP-ribose-P in four related males with gout.',
        'pmid' => '6204922',
        'hasTextMinedTerms' => 'N',
        'citedByCount' => 9
      }
    ]
  },
  'request' => {
    'page' => 1,
    'synonym' => bless( do{\(my $o = 0)}, 'JSON::XS::Boolean' ),
    'query' => '6204922',
    'resultType' => 'LITE'
  },
  'hitCount' => 1,
  'version' => '4.1'
}
=end
=cut


