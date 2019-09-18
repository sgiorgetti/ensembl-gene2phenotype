package Bio::EnsEMBL::G2P::Utils::Net;

use strict;
use warnings;

use base qw/Exporter/;
use Time::HiRes;
our @EXPORT_OK;

@EXPORT_OK = qw(
  do_GET
  do_POST
);

use Bio::EnsEMBL::Utils::Exception qw(throw);

our $HTTP_TINY = 0;
eval {
  require HTTP::Tiny;
  $HTTP_TINY = 1;
};

sub do_GET {
  my ($url, $total_attempts, $sleep) = @_;
  return _retry_sleep(sub {
    return _get_http_tiny($url);
  }, $total_attempts, $sleep);
}

sub do_POST {
  my ($url, $data) = @_;
  return _post_http_tiny($url, $data);
}

sub _post_http_tiny {
  my ($url, $data) = @_;
  my $http = HTTP::Tiny->new();
  my $response = $http->post_form($url, $data,
  {
    'Content-type' => 'application/json',
    'Accept' => 'application/json',
  },);
  return unless $response->{success};
  return $response->{content} if length $response->{content};
  return;
}

sub _retry_sleep {
  my ($callback, $total_attempts, $sleep) = @_;
  $total_attempts ||= 1;
  $sleep ||= 0;
  my $response;
  my $retries = 0;
  my $fail = 1;
  while($retries <= $total_attempts) {
    $response = $callback->();
    if(defined $response) {
      $fail = 0;
      last;
    }
    $retries++;
    Time::HiRes::sleep($sleep);
  }
  if($fail) {
    throw "Could not request remote resource after $total_attempts attempts";
  }
  return $response;
}

sub _get_http_tiny {
  my ($url) = @_;
  my $response = HTTP::Tiny->new->get($url);

#  my $http = HTTP::Tiny->new(
#    http_proxy => 'http://10.7.48.163:3128',
#    proxy => 'http://10.7.48.163:3128',
#  );
#  my $response = $http->get($url);
  return unless $response->{success};
  return $response->{content} if length $response->{content};
  return;
}

