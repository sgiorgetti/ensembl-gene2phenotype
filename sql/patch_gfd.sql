-- See the NOTICE file distributed with this work for additional information
-- regarding copyright ownership.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
ALTER TABLE genomic_feature_disease ADD COLUMN disease_name varchar(255) DEFAULT NULL AFTER disease_id;
ALTER TABLE genomic_feature_disease ADD COLUMN disease_mim int(10) unsigned DEFAULT NULL AFTER disease_name;
ALTER TABLE genomic_feature_disease ADD COLUMN allelic_requirement_attrib set('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20') DEFAULT NULL AFTER disease_mim;
ALTER TABLE genomic_feature_disease ADD COLUMN mutation_consequence_attrib set('21', '22', '23', '24', '25', '26', '27', '28', '29', '30') DEFAULT NULL AFTER allelic_requirement_attrib;
