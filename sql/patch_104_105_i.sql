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


INSERT IGNORE into attrib (attrib_id, attrib_type_id, value) VALUES (116, 16, 'NMD_triggering');
INSERT IGNORE into attrib (attrib_id, attrib_type_id, value) VALUES (117, 16, 'NMD_escaping');
INSERT IGNORE into attrib (attrib_id, attrib_type_id, value) VALUES (118, 16, 'stop_gained_NMD_triggering');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (119, 16, 'stop_gained_NMD_escaping');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (120, 16, 'splice_donor_variant_NMD_triggering');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (121, 16, 'frameshift_variant_NMD_triggering');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (122, 16, 'splice_acceptor_variant_NMD_escaping');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (123, 16, 'splice_acceptor_variant_NMD_triggering');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (124, 16, 'splice_donor_variant_NMD_escaping');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (125, 16, 'frameshift_variant_NMD_escaping');

ALTER TABLE genomic_feature_disease MODIFY COLUMN variant_consequence_attrib set('100','101','102','103','104','105','106','107','108','109','110','111','112','113','114','115','116','117','118','119','120','121','122','123','124','125') DEFAULT NULL AFTER mutation_consequence_flag_attrib;

ALTER TABLE genomic_feature_disease_log MODIFY COLUMN variant_consequence_attrib set('100','101','102','103','104','105','106','107','108','109','110','111','112','113','114','115','116','117','118','119','120','121','122','123','124','125') DEFAULT NULL AFTER mutation_consequence_flag_attrib;

ALTER TABLE genomic_feature_disease_deleted MODIFY COLUMN variant_consequence_attrib set('100','101','102','103','104','105','106','107','108','109','110','111','112','113','114','115','116','117','118','119','120','121','122','123','124','125') DEFAULT NULL AFTER mutation_consequence_flag_attrib;

INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'patch', 'patch_104_105_i.sql|adding new attrib variant consequences to support cardiac'); 
