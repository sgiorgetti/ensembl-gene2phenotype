=head1 LICENSE
 
See the NOTICE file distributed with this work for additional information
regarding copyright ownership.
 
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
  my ($url, $http_proxy, $proxy, $total_attempts, $sleep) = @_;
  return _retry_sleep(sub {
    return _get_http_tiny($url, $http_proxy, $proxy);
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
  my ($url, $http_proxy, $proxy) = @_;
  my $response;
  if ($http_proxy && $proxy) {
    my $http = HTTP::Tiny->new(
      http_proxy => $http_proxy,
      proxy => $proxy,
    );
    $response = $http->get($url);
  } else {
    $response = HTTP::Tiny->new->get($url);
  }
  return unless $response->{success};
  return $response->{content} if length $response->{content};
  return;
}
1;
