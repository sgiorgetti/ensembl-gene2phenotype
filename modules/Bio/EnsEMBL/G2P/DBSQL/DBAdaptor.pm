=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

package Bio::EnsEMBL::G2P::DBSQL::DBAdaptor;

use Bio::EnsEMBL::DBSQL::DBAdaptor;

our @ISA = ('Bio::EnsEMBL::DBSQL::DBAdaptor');

sub get_available_adaptors {

  my %pairs = (
    'Attribute'                        => 'Bio::EnsEMBL::G2P::DBSQL::AttributeAdaptor',
    'Disease'                          => 'Bio::EnsEMBL::G2P::DBSQL::DiseaseAdaptor',
    'EnsemblVariation'                 => 'Bio::EnsEMBL::G2P::DBSQL::EnsemblVariationAdaptor',
    'GFDPhenotypeComment'              => 'Bio::EnsEMBL::G2P::DBSQL::GFDPhenotypeCommentAdaptor',
    'GFDPublicationComment'            => 'Bio::EnsEMBL::G2P::DBSQL::GFDPublicationCommentAdaptor',
    'GenomicFeature'                   => 'Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureAdaptor',
    'GenomicFeatureDisease'            => 'Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseAdaptor',
    'GenomicFeatureDiseaseLog'         => 'Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseLogAdaptor',
    'GenomicFeatureDiseaseAction'      => 'Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseActionAdaptor',
    'GenomicFeatureDiseaseActionLog'   => 'Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseActionLogAdaptor',
    'GenomicFeatureDiseaseComment'     => 'Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseCommentAdaptor',
    'GenomicFeatureDiseaseOrgan'       => 'Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseOrganAdaptor',
    'GenomicFeatureDiseasePhenotype'   => 'Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseasePhenotypeAdaptor',
    'GenomicFeatureDiseasePublication' => 'Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseasePublicationAdaptor',   
    'Organ'                            => 'Bio::EnsEMBL::G2P::DBSQL::OrganAdaptor',
    'Panel'                            => 'Bio::EnsEMBL::G2P::DBSQL::PanelAdaptor',
    'Phenotype'                        => 'Bio::EnsEMBL::G2P::DBSQL::PhenotypeAdaptor',
    'Publication'                      => 'Bio::EnsEMBL::G2P::DBSQL::PublicationAdaptor',
    'User'                             => 'Bio::EnsEMBL::G2P::DBSQL::UserAdaptor',
    'Variation'                        => 'Bio::EnsEMBL::G2P::DBSQL::VariationAdaptor',
  );

  return (\%pairs);
}

1;
