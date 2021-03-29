CREATE TABLE IF NOT EXISTS genomic_feature_disease_panel (
  genomic_feature_disease_panel_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  genomic_feature_disease_id int(10) unsigned NOT NULL,
  confidence_category_attrib set('31','32','33','34','35') DEFAULT NULL,
  is_visible tinyint(1) unsigned NOT NULL DEFAULT '1',
  panel_attrib tinyint(1) DEFAULT NULL,
  PRIMARY KEY (genomic_feature_disease_panel_id),
  UNIQUE KEY gfd_panel_idx (genomic_feature_disease_id, panel_attrib),
  KEY genomic_feature_disease_idx (genomic_feature_disease_id)
);

CREATE TABLE IF NOT EXISTS genomic_feature_disease_panel_log (
  genomic_feature_disease_panel_log_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  genomic_feature_disease_panel_id int(10) unsigned NOT NULL,
  genomic_feature_disease_id int(10) unsigned NOT NULL,
  confidence_category_attrib set('31','32','33','34','35') DEFAULT NULL,
  is_visible tinyint(1) unsigned NOT NULL DEFAULT '1',
  panel_attrib tinyint(1) DEFAULT NULL,
  created timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  user_id int(10) unsigned NOT NULL,
  action varchar(128) NOT NULL,
  PRIMARY KEY (genomic_feature_disease_panel_log_id),
  KEY genomic_feature_disease_panel_idx (genomic_feature_disease_panel_id),
  KEY genomic_feature_disease_idx (genomic_feature_disease_id)
);

CREATE TABLE IF NOT EXISTS genomic_feature_disease_panel_deleted (
  genomic_feature_disease_panel_deleted_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  genomic_feature_disease_panel_id int(10) unsigned NOT NULL,
  genomic_feature_disease_id int(10) unsigned NOT NULL,
  confidence_category_attrib set('31','32','33','34','35') DEFAULT NULL,
  is_visible tinyint(1) unsigned NOT NULL DEFAULT '1',
  panel_attrib tinyint(1) DEFAULT NULL,
  deleted timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  deleted_by_user_id int(10) unsigned NOT NULL,
  PRIMARY KEY (genomic_feature_disease_panel_deleted_id),
  UNIQUE KEY gfd_panel_idx (genomic_feature_disease_id, panel_attrib),
  KEY genomic_feature_disease_idx (genomic_feature_disease_id)
);
