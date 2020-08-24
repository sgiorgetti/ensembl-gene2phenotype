CREATE TABLE IF NOT EXISTS location_feature (
  location_feature_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  seq_region_name varchar(255) DEFAULT NULL,
  seq_region_start int(10) unsigned DEFAULT NULL,
  seq_region_end int(10) unsigned DEFAULT NULL,
  seq_region_strand tinyint(2) NOT NULL,
  PRIMARY KEY (location_feature_id),
  UNIQUE KEY location_idx (seq_region_name, seq_region_start, seq_region_end, seq_region_strand)
);

CREATE TABLE IF NOT EXISTS gene_feature (
  gene_feature_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  seq_region_name  varchar(255) DEFAULT NULL,
  seq_region_start int(10) unsigned DEFAULT NULL,
  seq_region_end int(10) unsigned DEFAULT NULL,
  seq_region_strand tinyint(2) NOT NULL,
  gene_symbol varchar(128) DEFAULT NULL,
  hgnc_id int(10) unsigned DEFAULT NULL,
  mim int(10) unsigned DEFAULT NULL,
  ensembl_stable_id varchar(128) DEFAULT NULL, 
  PRIMARY KEY (gene_feature_id),
  UNIQUE KEY location_idx (seq_region_name, seq_region_start, seq_region_end, seq_region_strand),
  KEY gene_symbol_idx (gene_symbol)
);

CREATE TABLE IF NOT EXISTS gene_feature_synonym (
  gene_feature_id int(10) unsigned NOT NULL,
  name varchar(255) NOT NULL,
  UNIQUE KEY name (gene_feature_id, name),
  KEY gene_feature_idx (gene_feature_id)
);

CREATE TABLE IF NOT EXISTS allele_feature (
  allele_feature_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  seq_region_name varchar(255) DEFAULT NULL,
  seq_region_start int(10) unsigned DEFAULT NULL,
  seq_region_end int(10) unsigned DEFAULT NULL,
  seq_region_strand tinyint(2) NOT NULL,
  name varchar(255) DEFAULT NULL,
  ref_allele varchar(255) DEFAULT NULL,
  alt_allele varchar(255) DEFAULT NULL,
  hgvs_genomic text  DEFAULT NULL,
  PRIMARY KEY (allele_feature_id),
  UNIQUE KEY unique_allele_idx (seq_region_name, seq_region_start, seq_region_end, seq_region_strand, alt_allele),
  KEY hgvs_genomic_idx (hgvs_genomic(255))
);

CREATE TABLE IF NOT EXISTS transcript_allele (
  transcript_allele_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  allele_feature_id int(10) unsigned NOT NULL,
  gene_feature_id int(10) unsigned NOT NULL,
  transcript_stable_id varchar(128) DEFAULT NULL,
  consequence_types varchar(255) DEFAULT NULL,
  cds_start int(11) unsigned DEFAULT NULL,
  cds_end int(11) unsigned DEFAULT NULL,
  cdna_start int(11) unsigned DEFAULT NULL,
  cdna_end int(11) unsigned DEFAULT NULL,
  translation_start int(11) unsigned DEFAULT NULL,
  translation_end int(11) unsigned DEFAULT NULL,
  codon_allele_string text,
  pep_allele_string text,
  hgvs_transcript text,
  hgvs_protein text,
  cadd int(11) unsigned DEFAULT NULL,
  sift_prediction enum('tolerated','deleterious','tolerated - low confidence','deleterious - low confidence') DEFAULT NULL,
  polyphen_prediction enum('unknown','benign','possibly damaging','probably damaging') DEFAULT NULL,
  appris varchar(255) DEFAULT NULL,
  tsl int(11) unsigned DEFAULT NULL,
  mane varchar(255) DEFAULT NULL,
  PRIMARY KEY (transcript_allele_id),
  UNIQUE KEY unique_transcript_allele_idx (allele_feature_id, transcript_stable_id),
  KEY gene_feature_idx (gene_feature_id),
  KEY allele_feature_idx (allele_feature_id)
);

CREATE TABLE IF NOT EXISTS locus_genotype_mechanism (
  locus_genotype_mechanism_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  locus_type enum('location','gene','allele') DEFAULT NULL,
  locus_id int(10) unsigned NOT NULL,
  genotype_attrib set('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20') NOT NULL,
  mechanism_attrib set('21','22','23','24','25','26','27','28','29','30','44') NOT NULL,
  PRIMARY KEY (locus_genotype_mechanism_id),
  UNIQUE KEY genotype_mechanism_idx (locus_type, locus_id, genotype_attrib, mechanism_attrib)
);  

CREATE TABLE IF NOT EXISTS LGM_panel (
  LGM_panel_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  locus_genotype_mechanism_id int(10) unsigned NOT NULL,
  panel_id int(10) unsigned NOT NULL,
  confidence_category_attrib set('31','32','33','34','35') DEFAULT NULL,
  user_id int(10) unsigned NOT NULL,
  created timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (LGM_panel_id),
  UNIQUE KEY lgm_panel_idx (locus_genotype_mechanism_id, panel_id),
  KEY lgm_idx (locus_genotype_mechanism_id),
  KEY panel_idx (panel_id)
);

CREATE TABLE IF NOT EXISTS LGM_panel_disease (
  LGM_panel_disease_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  LGM_panel_id int(10) unsigned NOT NULL,
  disease_id int(10) unsigned NOT NULL,
  user_id int(10) unsigned NOT NULL,
  created timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (LGM_panel_disease_id),
  UNIQUE KEY lgm_panel_disease_idx (LGM_panel_id, disease_id),
  KEY lgm_panel_idx (LGM_panel_id)
);

CREATE TABLE IF NOT EXISTS LGM_publication (
  LGM_publication_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  locus_genotype_mechanism_id int(10) unsigned NOT NULL,
  publication_id int(10) unsigned NOT NULL,
  user_id int(10) unsigned NOT NULL,
  created timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (LGM_publication_id),
  UNIQUE KEY lgm_publication_idx (locus_genotype_mechanism_id, publication_id),
  KEY lgm_idx (locus_genotype_mechanism_id)
);

