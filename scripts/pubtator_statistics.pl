use strict;
use warnings;
use FileHandle;

# unique PMID IDs
my $fh = FileHandle->new('/hps/nobackup/production/ensembl/anja/G2P/text_mining/data/gene2pubtator');


my $pmids = {};
my $gene_ids = {};

while (<$fh>) {
  chomp;
  next if /^PMID/;
  my ($pmid, $gene_id, $mentions, $reference) = split/\t/;
  $pmids->{$pmid}++;
  $gene_ids->{$gene_id} = 1;
}
$fh->close;


print STDERR "PMIDs ", scalar keys %$pmids, "\n";
print STDERR "GeneIDs ", scalar keys %$gene_ids, "\n";

foreach my $pmid (sort { $pmids->{$b} <=> $pmids->{$a} } keys %$pmids) {
    print STDERR $pmid, ' ', $pmids->{$pmid}, "\n";
}
