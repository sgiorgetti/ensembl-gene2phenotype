use strict;
use warnings;

use Text::CSV;
use FileHandle;

my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
            or die "Cannot use CSV: ".Text::CSV->error_diag ();

open my $fh, "<:encoding(utf8)", "/hps/nobackup/production/ensembl/anja/G2P/text_mining/data/mappings.csv" or die "mappings.csv: $!";
#curie_id label mapped_curie  mapped_label  mapping_source_prefix mapping_target_prefix distance
my $mashIDs = {};
while ( my $row = $csv->getline( $fh ) ) {
  next if ($row->[0] eq 'curie_id');
  my $curie_id = $row->[0];
  next if ($curie_id !~ /^MeSH/);
  my $label = $row->[1];
  my $mapped_curie = $row->[2];
  my $mapped_label = $row->[3];
  $mashIDs->{$curie_id}->{label} = $label;
  $mashIDs->{$curie_id}->{mappings}->{$mapped_curie} = $mapped_label;
}
$csv->eof or $csv->error_diag();
close $fh;


$fh = FileHandle->new('/hps/nobackup/production/ensembl/anja/G2P/text_mining/data/ebi_oxo_mappings.txt', 'w');

foreach my $mashID (keys %$mashIDs) {
  my $label = $mashIDs->{$mashID}->{label};
  my $mappings = join(',', keys %{$mashIDs->{$mashID}->{mappings}});
  print $fh "$mashID\t$label\t$mappings\n";
} 

$fh->close;
