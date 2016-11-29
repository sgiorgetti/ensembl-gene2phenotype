package Bio::EnsEMBL::G2P::Utils::Downloads;
use Text::CSV;
use Bio::EnsEMBL::Registry;

use base qw(Exporter);
our @EXPORT_OK = qw( download_data );


sub download_data {
  my $downloads_dir = shift;
  my $file_name = shift;
  my $registry_file = shift;

  my $registry = 'Bio::EnsEMBL::Registry';
  $registry->load_all($registry_file);

  my $file = "$downloads_dir/$file_name";
  my $panel_name = $file_name;
  $panel_name =~ s/G2P\.csv//;
  print STDERR $panel_name, "\n";
  
  my $GFD_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');
  my $dbh = $GFD_adaptor->dbc->db_handle;

  my $csv = Text::CSV->new ( { binary => 1, eol => "\r\n" } ) or die "Cannot use CSV: ".Text::CSV->error_diag ();
  open my $fh, ">:encoding(utf8)", "$file" or die "$file: $!";
  $csv->print($fh, ['gene symbol', 'gene mim', 'disease name', 'disease mim', 'DDD category', 'allelic requirement', 'mutation consequence', 'phenotypes', 'organ specificity list', 'pmids', 'panel', 'prev symbols']);

  $csv->eol ("\r\n");

  my $gfd_attribute_tables = {
    phenotype => {sql => 'SELECT gfdp.genomic_feature_disease_id, p.stable_id FROM genomic_feature_disease_phenotype gfdp, phenotype p WHERE gfdp.phenotype_id = p.phenotype_id;'},
    organ => {sql => 'SELECT gfdo.genomic_feature_disease_id, o.name FROM genomic_feature_disease_organ gfdo, organ o WHERE gfdo.organ_id = o.organ_id'},
    publication => {sql => 'SELECT gfdp.genomic_feature_disease_id, p.pmid FROM genomic_feature_disease_publication gfdp, publication p WHERE gfdp.publication_id = p.publication_id;'},
  };

  my $gfd_attributes = {};
  foreach my $table (keys %$gfd_attribute_tables) {
    my $sql = $gfd_attribute_tables->{$table}->{sql};
    my $sth = $dbh->prepare($sql);
    $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
    while (my $row = $sth->fetchrow_arrayref()) {
      my ($id, $value) = @$row;
      $gfd_attributes->{$id}->{$table}->{$value} = 1;
    }
  }

  my $gfid2synonyms = {};
  my $sth = $dbh->prepare('SELECT genomic_feature_id, name FROM genomic_feature_synonym;');
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my ($id, $value) = @$row;
    $gfid2synonyms->{$id}->{$value} = 1;
  }

  my $attribs = {};
  $sth = $dbh->prepare(q{SELECT attrib_id, value FROM attrib;});
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  while (my $row = $sth->fetchrow_arrayref()) {
    my ($id, $value) = @$row;
    $attribs->{$id} = $value;
  }
  my $where = ($panel_name eq 'ALL') ? '' : "WHERE a.value = '$panel_name'";

  $sth = $dbh->prepare(qq{
    SELECT gfd.genomic_feature_disease_id, gf.gene_symbol, gf.mim, d.name, d.mim, gfd.DDD_category_attrib, gfda.allelic_requirement_attrib, gfda.mutation_consequence_attrib, a.value, gf.genomic_feature_id
    FROM genomic_feature_disease gfd
    LEFT JOIN genomic_feature_disease_action gfda ON gfd.genomic_feature_disease_id = gfda.genomic_feature_disease_id
    LEFT JOIN genomic_feature gf ON gfd.genomic_feature_id = gf.genomic_feature_id
    LEFT JOIN disease d ON gfd.disease_id = d.disease_id
    LEFT JOIN attrib a ON gfd.panel_attrib = a.attrib_id
    $where;
  });
  $sth->execute() or die 'Could not execute statement: ' . $sth->errstr;
  my ($gfd_id, $gene_symbol, $gene_mim, $disease_name, $disease_mim, $DDD_category_attrib, $ar_attrib, $mc_attrib, $panel, $gfid, $prev_symbols);
  $sth->bind_columns(\($gfd_id, $gene_symbol, $gene_mim, $disease_name, $disease_mim, $DDD_category_attrib, $ar_attrib, $mc_attrib, $panel, $gfid));
  while ( $sth->fetch ) {
    $gene_symbol ||= 'No gene symbol';
    $gene_mim ||= 'No gene mim';
    $disease_name ||= 'No disease name';
    $disease_mim ||= 'No disease mim';
    my $DDD_category = ($DDD_category_attrib) ? $attribs->{$DDD_category_attrib} : 'No DDD category';
    my $allelic_requirement = ($ar_attrib) ? join(',', map { $attribs->{$_} } split(',', $ar_attrib)) : undef;
    my $mutation_consequence = ($mc_attrib) ? join(',', map { $attribs->{$_} } split(',', $mc_attrib)) : undef;

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
  
    my @row = ($gene_symbol, $gene_mim, $disease_name, $disease_mim, $DDD_category, $allelic_requirement, $mutation_consequence, @annotations, $panel, $prev_symbols);

    $csv->print ($fh, \@row);
  }
  close $fh or die "$csv: $!";
  system("/usr/bin/gzip $file");
  return 1;
}

1;
