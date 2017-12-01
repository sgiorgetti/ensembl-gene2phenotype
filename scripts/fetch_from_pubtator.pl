use strict;
use warnings;

use HTTP::Tiny;
use JSON;
use Data::Dumper;
use FileHandle;


my $http = HTTP::Tiny->new();

my $server = 'https://www.ncbi.nlm.nih.gov/CBBresearch/Lu/Demo/RESTful/tmTool.cgi/Gene,Disease,Mutation/11443545/PubAnnotation/'; 
my $response = $http->get($server, {
  headers => { 'Content-type' => 'text/html' }
});
if ($response->{success}) {
  if (length $response->{content}) {
    my $hash = decode_json($response->{content});
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
#    print Dumper $hash;
#    print "\n";
    my $abstract = $hash->{text};
    my $denotations = $hash->{denotations};
    my @sorted_denotations = sort {$a->{span}->{begin} <=> $b->{span}->{begin}} @$denotations;
    my $start = 0;
    
    foreach my $denotation (@sorted_denotations) {
      my $denotation_start = $denotation->{span}->{begin};
      my $denotation_end = $denotation->{span}->{end};
      my $end = $denotation_start - 1;
      if ($end != -1) {
        print "$start - $end\n";
        my $length = $end - $start + 1;
        my $text = substr $abstract, $start, $length;
        print $text, "\n";
      }
      print "$denotation_start - $denotation_end\n";
      my $length = $denotation_end - $denotation_start + 1;
      my $text = substr $abstract, $denotation_start, $length;
      print $text, "\n";
      $start = $denotation_end + 1;
    }
  }
}
