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


ALTER TABLE genomic_feature_disease DROP COLUMN confidence_category_attrib, DROP COLUMN is_visible;
ALTER TABLE genomic_feature_disease DROP INDEX genomic_feature_disease;
CREATE UNIQUE INDEX genomic_feature_disease ON genomic_feature_disease(`genomic_feature_id`,`allelic_requirement_attrib`,`mutation_consequence_attrib`,`disease_id`);
