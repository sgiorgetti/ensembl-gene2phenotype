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
$registry->load_all('/Users/anja/Documents/G2P/ensembl.registry');

my $dbh = $registry->get_DBAdaptor('human', 'gene2phenotype')->dbc->db_handle; 

main();

sub main {
  my $http = HTTP::Tiny->new();
  my $server = 'http://www.ebi.ac.uk/europepmc/webservices/rest/search/query=ext_id:';
  
  my $pmids = get_pmids();
  foreach my $pmid (keys %$pmids) {
    my $response = $http->get($server.$pmid.'&format=json');
    die "Failed !\n" unless $response->{success};
     
    if (length $response->{content}) {
      my $hash = decode_json($response->{content});
      my $result = $hash->{resultList}->{result}[0];
      my $title = $result->{title};
      next if (!$title);
      $title =~ s/'/\\'/g;
      my $journalTitle = $result->{journalTitle};
      my $journalVolume = $result->{journalVolume};
      my $pageInfo = $result->{pageInfo};
      my $pubYear = $result->{pubYear}; 
      my $source = '';
      $source .= "$journalTitle. " if ($journalTitle);
      $source .= "$journalVolume: " if ($journalVolume);
      $source .= "$pageInfo, " if ($pageInfo);
      $source .= "$pubYear." if ($pubYear);
      $source =~ s/'/\\'/g;
      my $title_length = length($title);
      my $old_title = $pmids->{$pmid}->{title};
      $old_title =~ s/'/\\'/g;

#      $old_title = decode('utf8', $old_title);
      my $old_source = $pmids->{$pmid}->{source};
      $old_source =~ s/'/\\'/g;

#      $old_source = decode('utf8', $old_source);
      $title = encode('utf8', $title);
      $source = encode('utf8', $source);
      if (!$old_source || $old_source ne $source || !$old_title || $old_title ne $title) {
        print STDERR "OLD $pmid $old_title $old_source\n";
        print STDERR "NEW $pmid $title $source\n\n";
        $dbh->do(qq{UPDATE publication SET title='$title' WHERE pmid=$pmid;}) or die $dbh->errstr;  
        $dbh->do(qq{UPDATE publication SET source='$source' WHERE pmid=$pmid;}) or die $dbh->errstr;  
      }
    }
  }
}


sub get_pmids {
  my $pmids = {};
  my $sth = $dbh->prepare(q{
    SELECT pmid, title, source FROM publication;
  }); 
  $sth->execute() or die 'Could not execute statement ' . $sth->errstr;
  my ($pmid, $title, $source);
  $sth->bind_columns(\($pmid, $title, $source));
  while (my $row = $sth->fetchrow_arrayref()) {
    if ($pmid) {
      $pmids->{$pmid}->{title} = $title;
      $pmids->{$pmid}->{source} = $source;
    }
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


