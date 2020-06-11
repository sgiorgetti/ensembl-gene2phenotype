=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2020] EMBL-European Bioinformatics Institute
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

use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $pa = $g2pdb->get_PublicationAdaptor;

ok($pa && $pa->isa('Bio::EnsEMBL::G2P::DBSQL::PublicationAdaptor'), 'isa publication_adaptor');

my $publication_id = 881;
my $pmid = 19088120;

my $publication = $pa->fetch_by_publication_id($publication_id);
ok($publication->dbID == $publication_id, 'fetch_by_publication_id');

$publication = $pa->fetch_by_dbID($publication_id);
ok($publication->dbID == $publication_id, 'fetch_by_dbID');

$publication = $pa->fetch_by_PMID($pmid);
ok($publication->pmid == $pmid, 'fetch_by_PMID');

$publication = Bio::EnsEMBL::G2P::Publication->new(
  -title => 'test_publication',
  -adaptor => $pa,
);

ok($pa->store($publication), 'store');

$publication_id = $publication->{publication_id};

my $dbh = $pa->dbc->db_handle;
$dbh->do(qq{DELETE FROM publication WHERE publication_id=$publication_id;}) or die $dbh->errstr;

done_testing();
1;
