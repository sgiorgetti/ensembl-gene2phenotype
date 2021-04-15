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
package Bio::EnsEMBL::G2P::Utils::Downloads;
use strict;
use warnings;
use Text::CSV;
use Bio::EnsEMBL::Registry;
use base qw(Exporter);
our @EXPORT_OK = qw( download_data );

my $gfd_attributes = {};
my $gfd_create_dates = {};
my $gfid2synonyms = {};
my $confidence_category_attribs = {};
my $allelic_requirement_attribs = {};
my $mutation_consequence_attribs = {};


sub download_data {
  my $downloads_dir = shift;
  my $file_name = shift;
  my $registry_file = shift;
  my $is_logged_in = shift;
  my $user_panels = shift;
  my $panel_name = shift;
  my $registry = 'Bio::EnsEMBL::Registry';
  $registry->load_all($registry_file);

  my $file = "$downloads_dir/$file_name";
  
  my $GFD_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');
  my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
  my $panels = $attribute_adaptor->get_values_by_type('g2p_panel');
  $confidence_category_attribs = $attribute_adaptor->get_attribs_by_type('confidence_category');  
  $allelic_requirement_attribs = $attribute_adaptor->get_attribs_by_type('allelic_requirement');
  $mutation_consequence_attribs = $attribute_adaptor->get_attribs_by_type('mutation_consequence');

  my $dbh = $GFD_adaptor->dbc->db_handle;

  my $csv = Text::CSV->new ( { binary => 1, eol => "\r\n" } ) or die "Cannot use CSV: ".Text::CSV->error_diag ();
  open my $fh, ">:encoding(utf8)", "$file" or die "$file: $!";
  $csv->print($fh, ['gene symbol', 'gene mim', 'disease name', 'disease mim', 'DDD category', 'allelic requirement', 'mutation consequence', 'phenotypes', 'organ specificity list', 'pmids', 'panel', 'prev symbols', 'hgnc id', 'gene disease pair entry date']);

  $csv->eol ("\r\n");

  my $gfd_attribute_tables = {
    phenotype => {sql => 'SELECT gfdp.genomic_feature_disease_id, p.stable_id FROM genomic_feature_disease_phenotype gfdp, phenotype p WHERE gfdp.phenotype_id = p.phenotype_id;'},
    organ => {sql => 'SELECT gfdo.genomic_feature_disease_id, o.name FROM genomic_feature_disease_organ gfdo, organ o WHERE gfdo.organ_id = o.organ_id'},
    publication => {sql => 'SELECT gfdp.genomic_feature_disease_id, p.pmid FROM genomic_feature_disease_publication gfdp, publication p WHERE gfdp.publication_id = p.publication_id;'},
  };

  foreach my $table (keys %$gfd_attribute_tables) {
    my $sql = $gfd_attribute_tables->{$table}->{sql};
    my $sth = $dbh->prepare($sql);
    $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
    while (my $row = $sth->fetchrow_arrayref()) {
      my ($id, $value) = @$row;
      $gfd_attributes->{$id}->{$table}->{$value} = 1;
    }
  }

  my $sth = $dbh->prepare('SELECT genomic_feature_id, name FROM genomic_feature_synonym;');
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my ($id, $value) = @$row;
    $gfid2synonyms->{$id}->{$value} = 1;
  }

  $sth = $dbh->prepare(q{SELECT genomic_feature_disease_id, created FROM genomic_feature_disease_log WHERE action='create';});
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my ($gfd_id, $created) = @$row;
    $gfd_create_dates->{$gfd_id} = $created;
  }
  $sth->finish();

  my $where = ($panel_name eq 'ALL') ? 'WHERE gfdp.is_visible = 1' : "WHERE a.value = '$panel_name' AND gfdp.is_visible = 1";

  if ($is_logged_in) {
    if ($panel_name eq 'ALL') {
      foreach my $panel (keys %$panels) {
        next if ($panel eq 'ALL');
        if (grep {$panel eq $_} @$user_panels) {
          $where =  "WHERE a.value = '$panel'";
        } else {
          $where =  "WHERE a.value = '$panel' AND gfdp.is_visible = 1";
        }
        write_data($dbh, $csv, $fh, $where);
      }
    } else {
      if (grep {$panel_name eq $_} @$user_panels) {
        $where =  "WHERE a.value = '$panel_name'";
      } else {
        $where =  "WHERE a.value = '$panel_name' AND gfdp.is_visible = 1";
      }
      write_data($dbh, $csv, $fh, $where);
    }
  } else {
    write_data($dbh, $csv, $fh, $where);
  } 

  close $fh or die "$csv: $!";
  system("/usr/bin/gzip $file");
  return 1;
}

sub write_data {
  my $dbh = shift;
  my $csv = shift;
  my $fh = shift;
  my $where = shift;
  my $sth = $dbh->prepare(qq{
    SELECT gfd.genomic_feature_disease_id, gf.gene_symbol, gf.hgnc_id, gf.mim, d.name, d.mim, gfdp.confidence_category_attrib, gfd.allelic_requirement_attrib, gfd.mutation_consequence_attrib, a.value, gf.genomic_feature_id
    FROM genomic_feature_disease gfd
    LEFT JOIN genomic_feature_disease_panel gfdp ON gfd.genomic_feature_disease_id = gfdp.genomic_feature_disease_id
    LEFT JOIN genomic_feature gf ON gfd.genomic_feature_id = gf.genomic_feature_id
    LEFT JOIN disease d ON gfd.disease_id = d.disease_id
    LEFT JOIN attrib a ON gfdp.panel_attrib = a.attrib_id
    $where;
  });
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;


  my ($gfd_id, $gene_symbol, $hgnc_id, $gene_mim, $disease_name, $disease_mim, $confidence_category_attrib, $ar_attrib, $mc_attrib, $panel, $gfid, $prev_symbols, $created);
  $sth->bind_columns(\($gfd_id, $gene_symbol, $hgnc_id, $gene_mim, $disease_name, $disease_mim, $confidence_category_attrib, $ar_attrib, $mc_attrib, $panel, $gfid));
  while ( $sth->fetch ) {
    $gene_symbol ||= 'No gene symbol';
    $hgnc_id ||= 'No hgnc id';
    $gene_mim ||= 'No gene mim';
    $disease_name ||= 'No disease name';
    $disease_mim ||= 'No disease mim';

    my $confidence_category = ($confidence_category_attrib) ? $confidence_category_attribs->{$confidence_category_attrib} : 'No confidence category';
    my $allelic_requirement = ($ar_attrib) ? join(',', map { $allelic_requirement_attribs->{$_} } split(',', $ar_attrib)) : undef;
    my $mutation_consequence = ($mc_attrib) ? join(',', map { $mutation_consequence_attribs->{$_} } split(',', $mc_attrib)) : undef;

    my @annotations = ();
    if ($gfd_attributes->{$gfd_id}) {
      foreach my $table (qw/phenotype organ publication/) {
        if ($gfd_attributes->{$gfd_id}->{$table}) {
          push @annotations, join(';', keys %{$gfd_attributes->{$gfd_id}->{$table}});
        } else {
          push @annotations, undef;
        }
      }
    } else {
      push @annotations, (undef, undef, undef);
    }
    $prev_symbols = undef; 
    if ($gfid2synonyms->{$gfid})  {
      $prev_symbols = join(';', keys %{$gfid2synonyms->{$gfid}});
    }  

    $created = $gfd_create_dates->{$gfd_id} || 'No date';
 
    my @row = ($gene_symbol, $gene_mim, $disease_name, $disease_mim, $confidence_category, $allelic_requirement, $mutation_consequence, @annotations, $panel, $prev_symbols, $hgnc_id, $created);

    $csv->print ($fh, \@row);
  }
  $sth->finish;

}

1;
