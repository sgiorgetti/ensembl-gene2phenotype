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

package Bio::EnsEMBL::G2P::Publication;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

our @ISA = ('Bio::EnsEMBL::Storable');

sub new {
  my $caller = shift;
  my $class = ref($caller) || $caller;

  my ($publication_id, $pmid, $title, $source, $adaptor) =
    rearrange(['publication_id', 'pmid', 'title', 'source', 'adaptor'], @_);

  my $self = bless {
    'publication_id' => $publication_id,
    'pmid' => $pmid,
    'title' => $title,
    'source' => $source,
    'adaptor' => $adaptor,
  }, $class;

  return $self;
}

sub dbID {
  my $self = shift;
  $self->{publication_id} = shift if @_;
  return $self->{publication_id};
}

sub publication_id {
  my $self = shift;
  $self->{publication_id} = shift if @_;
  return $self->{publication_id};
}

sub pmid {
  my $self = shift;
  $self->{pmid} = shift if @_;
  return $self->{pmid};
}

sub title {
  my $self = shift;
  $self->{title} = shift if @_;
  return $self->{title};
}

sub source {
  my $self = shift;
  $self->{source} = shift if @_;
  return $self->{source};
}

sub update_text_minig_results {
  my $self = shift;
  my $text_mining_disease_adaptor = $self->{adaptor}->db->get_TextMiningDiseaseAdaptor;
  

}

1;
