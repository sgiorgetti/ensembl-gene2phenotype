use strict;
use warnings;

use Bio::EnsEMBL::Registry;

my $registry = 'Bio::EnsEMBL::Registry';
my $updates = {
'Bone Marrow/Immune' => 'Bone Marrow/Immune',
'Brain/Cognition' => 'Brain/Cognition',
'Cancer predisposition' => 'Cancer predisposition',
'Ear' => 'Ear',
'Endocrine' => 'Endocrine/Metabolic',
'Endocrine/Metabolic' => 'Endocrine/Metabolic',
'Eye' => 'Eye',
'Face' => 'Face',
'GI tract' => 'GI tract',
'Genitalia' => 'Genitalia',
'Hair/Nails' => 'Skin/Hair/Nails',
'Heart/Cardiovasculature' => 'Heart/Cardiovasculature/Lymphatic',
'Heart/Cardiovasculature/Lymphatic' => 'Heart/Cardiovasculature/Lymphatic',
'Kidney Renal Tract' => 'Kidney Renal Tract',
'Lungs' => 'Respiratory tract',
'Multisystem' => 'Multisystem',
'Musculature' => 'Musculature',
'Peripheral nerves' => 'Spinal cord/Peripheral nerves',
'Respiratory tract' => 'Respiratory tract',
'Skeleton' => 'Skeleton',
'Skin' => 'Skin/Hair/Nails',
'Spinal cord/Peripheral nerves' => 'Spinal cord/Peripheral nerves',
'Teeth & Dentitian' => 'Teeth & Dentitian',
'Skin/Hair/Nails' => 'Skin/Hair/Nails',
};


# insert into organ 'Skin, Hair, Nails';
# delete organs:
#'Endocrine'
#'Hair/Nails'
#'Lungs'
#'Peripheral nerves'
#'Skin'
#'Heart/Cardiovasculature' 

$registry->load_all('/Users/anjathormann/Documents/G2P/scripts/ensembl.registry');
my $organ_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'organ');
my $GFD_organ_adaptor =  $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseaseOrgan');

my $organ_list = $organ_adaptor->fetch_all;
my $organ_name2id = {};
my $oldid2newid = {};
my $newid2organ = {};
my $id2organ = {};

foreach my $organ (@{$organ_list}) {
  $organ_name2id->{$organ->name} = $organ->dbID;  
  $id2organ->{$organ->dbID} = $organ;
}

foreach my $organ (@{$organ_list}) {
  my $organ_name = $organ->name;
  my $old_id = $organ->dbID;
  my $updated_organ = $updates->{$organ_name};
  my $new_id = $organ_name2id->{$updated_organ};
  $oldid2newid->{$old_id} = $new_id;
}

my $GFD_organs = $GFD_organ_adaptor->fetch_all;

foreach my $GFD_organ (@$GFD_organs) {
  my $organ = $GFD_organ->get_Organ;
  my $old_id = $organ->dbID;
  my $new_id = $oldid2newid->{$old_id};
  if ($old_id != $new_id) {
    my $new_organ = $id2organ->{$new_id};
    $GFD_organ->organ_id($new_organ->dbID);
    $GFD_organ_adaptor->update($GFD_organ);
    print $GFD_organ->dbID, ' ', $old_id, ' ', $new_id, "\n";
  }
}


  








