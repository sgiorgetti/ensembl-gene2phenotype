-- Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
-- Copyright [2016-2022] EMBL-European Bioinformatics Institute
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--      http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.


INSERT into attrib_type(code, name, description) VALUES('variant_consequence', 'Variant consequence', 'Variant consequence using certain SO terms');

INSERT into attrib(attrib_id, attrib_type_id, value) VALUES (100, 16, 'splice_region_variant'), (101, 16, 'splice_acceptor_variant'), (102, 16, 'splice_donor_variant')
(103, 16, 'start_lost'), (104, 16, 'frameshift_variant'), (105, 16, 'stop_gained'), (106, 16, 'stop_lost'),(107, 16, 'missense_variant'), (108, 16, 'inframe_deletion'),
(109, 16, 'inframe_deletion'), (110, 16, '5_prime_UTR_variant'), (111, 16, '3_prime_UTR_variant'), (112, 16, 'synonymous_variant'), (113, 16, 'intron_variant'), 
(114, 16, 'regulatory_region_variant'), (115, 16, 'intergenic_variant');

ALTER TABLE genomic_feature_disease ADD COLUMN variant_consequence_attrib set('100', '101', '102', '103', '104', '105', '106', '107', '108', '109', '110', '111', '112', '113', '114', '115') DEFAULT NULL;

ALTER TABLE genomic_feature_disease_log ADD COLUMN variant_consequence_attrib set('100', '101', '102', '103', '104', '105', '106', '107', '108', '109', '110', '111', '112', '113', '114', '115') DEFAULT NULL;

ALTER TABLE genomic_feature_disease_deleted ADD COLUMN variant_consequence_attrib set('100', '101', '102', '103', '104', '105', '106', '107', '108', '109', '110', '111', '112', '113', '114', '115') DEFAULT NULL;

# patch identifier
INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'patch', 'patch_104_105_f.sql|adding new attrib variant consequences'); 
