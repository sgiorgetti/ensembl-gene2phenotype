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


INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (50, 11, 'definitive');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (51, 11, 'limited');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (52, 11, 'strong');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (81, 11, 'moderate');



INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (54, 12, 'requires heterozygosity');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (55, 12, 'typically de novo');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (56, 12, 'typically mosaic');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (57, 12, 'typified by age related penetrance');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (58, 12, 'typified by reduced penetrance');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (70, 12, 'imprinted');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (49, 12, 'potential IF');

# patch identifier
INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'patch', 'patch_104_105_b.sql|schema version');