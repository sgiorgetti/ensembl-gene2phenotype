-- Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
-- Copyright [2016-2021] EMBL-European Bioinformatics Institute
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

# in genomic_feature_disease, genomic_feature_disease_deleted, genomic_feature_disease_log rename allelic_requirement_attrib to original_allelic_requirement_attrib
ALTER TABLE genomic_feature_disease CHANGE COLUMN allelic_requirement_attrib original_allelic_requirement_attrib set('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20') DEFAULT NULL;
ALTER TABLE genomic_feature_disease_deleted CHANGE COLUMN allelic_requirement_attrib original_allelic_requirement_attrib set('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20') DEFAULT NULL;
ALTER TABLE genomic_feature_disease_log CHANGE COLUMN allelic_requirement_attrib original_allelic_requirement_attrib set('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20') DEFAULT NULL;

# in genomic_feature_disease, genomic_feature_disease_deleted, genomic_feature_disease_log rename mutation_consequence_attrib to original_mutation_consequence_attrib
ALTER TABLE genomic_feature_disease CHANGE COLUMN mutation_consequence_attrib original_mutation_consequence_attrib set('21','22','23','24','25','26','27','28','29','30','44') DEFAULT NULL;
ALTER TABLE genomic_feature_disease_deleted CHANGE COLUMN mutation_consequence_attrib original_mutation_consequence_attrib set('21','22','23','24','25','26','27','28','29','30','44') DEFAULT NULL;
ALTER TABLE genomic_feature_disease_log CHANGE COLUMN mutation_consequence_attrib original_mutation_consequence_attrib set('21','22','23','24','25','26','27','28','29','30','44') DEFAULT NULL;

# in genomic_feature_disease, genomic_feature_disease_deleted, genomic_feature_disease_log create allelic_requirement_attrib, cross_cutting_modifier_attrib, mutation_consequence_attrib, mutation_consequence_flag_attrib
ALTER TABLE genomic_feature_disease ADD COLUMN allelic_requirement_attrib set('59','60','63','64','65','66','67','68') DEFAULT NULL AFTER original_allelic_requirement_attrib;
ALTER TABLE genomic_feature_disease ADD COLUMN cross_cutting_modifier_attrib set('54','55','56','57','58','70') DEFAULT NULL AFTER allelic_requirement_attrib;
ALTER TABLE genomic_feature_disease ADD COLUMN mutation_consequence_attrib int(10) unsigned DEFAULT '0' AFTER original_mutation_consequence_attrib;
ALTER TABLE genomic_feature_disease ADD COLUMN mutation_consequence_flag_attrib set('71','72','73','74') DEFAULT NULL AFTER mutation_consequence_attrib;

ALTER TABLE genomic_feature_disease_deleted ADD COLUMN allelic_requirement_attrib set('59','60','63','64','65','66','67','68') DEFAULT NULL AFTER original_allelic_requirement_attrib;
ALTER TABLE genomic_feature_disease_deleted ADD COLUMN cross_cutting_modifier_attrib set('54','55','56','57','58','70') DEFAULT NULL AFTER allelic_requirement_attrib;
ALTER TABLE genomic_feature_disease_deleted ADD COLUMN mutation_consequence_attrib int(10) unsigned DEFAULT '0' AFTER original_mutation_consequence_attrib;
ALTER TABLE genomic_feature_disease_deleted ADD COLUMN mutation_consequence_flag_attrib set('71','72','73','74') DEFAULT NULL AFTER mutation_consequence_attrib;

ALTER TABLE genomic_feature_disease_log ADD COLUMN allelic_requirement_attrib set('59','60','63','64','65','66','67','68') DEFAULT NULL AFTER original_allelic_requirement_attrib;
ALTER TABLE genomic_feature_disease_log ADD COLUMN cross_cutting_modifier_attrib set('54','55','56','57','58','70') DEFAULT NULL AFTER allelic_requirement_attrib;
ALTER TABLE genomic_feature_disease_log ADD COLUMN mutation_consequence_attrib int(10) unsigned DEFAULT '0' AFTER original_mutation_consequence_attrib;
ALTER TABLE genomic_feature_disease_log ADD COLUMN mutation_consequence_flag_attrib set('71','72','73','74') DEFAULT NULL AFTER mutation_consequence_attrib;

# in genomic_feature_disease_panel, genomic_feature_disease_panel_deleted, genomic_feature_disease_panel_log rename confidence_category_attrib to original_confidence_category_attrib
ALTER TABLE genomic_feature_disease_panel CHANGE COLUMN confidence_category_attrib original_confidence_category_attrib set('31','32','33','34','35') DEFAULT NULL;
ALTER TABLE genomic_feature_disease_panel_deleted CHANGE COLUMN confidence_category_attrib original_confidence_category_attrib set('31','32','33','34','35') DEFAULT NULL;
ALTER TABLE genomic_feature_disease_panel_log CHANGE COLUMN confidence_category_attrib original_confidence_category_attrib set('31','32','33','34','35') DEFAULT NULL;

# in genomic_feature_disease_panel, genomic_feature_disease_panel_deleted, genomic_feature_disease_panel_log create confidence_category_attrib, clinical_review
ALTER TABLE genomic_feature_disease_panel ADD COLUMN confidence_category_attrib int(10) unsigned DEFAULT '0' AFTER original_confidence_category_attrib;
ALTER TABLE genomic_feature_disease_panel ADD COLUMN clinical_review tinyint(1) unsigned DEFAULT '0' AFTER confidence_category_attrib;

ALTER TABLE genomic_feature_disease_panel_deleted ADD COLUMN confidence_category_attrib int(10) unsigned DEFAULT '0' AFTER original_confidence_category_attrib;
ALTER TABLE genomic_feature_disease_panel_deleted ADD COLUMN clinical_review tinyint(1) unsigned DEFAULT '0' AFTER confidence_category_attrib;

ALTER TABLE genomic_feature_disease_panel_log ADD COLUMN confidence_category_attrib int(10) unsigned DEFAULT '0' AFTER original_confidence_category_attrib;
ALTER TABLE genomic_feature_disease_panel_log ADD COLUMN clinical_review tinyint(1) unsigned DEFAULT '0' AFTER confidence_category_attrib;

# patch identifier
INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'patch', 'patch_103_104_e.sql|update and add new columns to genomic_feature_disease, genomic_feature_disease_panel, deleted and log tables');
