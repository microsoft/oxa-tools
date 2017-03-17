USE edxapp;
/*============catalog 0001=============================*/
BEGIN;
CREATE TABLE `catalog_catalogintegration` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `internal_api_url` varchar(200) NOT NULL, `cache_ttl` integer UNSIGNED NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `catalog_catalogintegration` ADD CONSTRAINT `catalog_catalogin_changed_by_id_4c786efa531d484b_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============catalog 0002=============================*/
BEGIN;
ALTER TABLE `catalog_catalogintegration` ADD COLUMN `service_username` varchar(100) DEFAULT 'lms_catalog_service_user' NOT NULL;
ALTER TABLE `catalog_catalogintegration` ALTER COLUMN `service_username` DROP DEFAULT;
COMMIT;
/*============coursewarehistoryextended       0001=============================*/
/*============coursewarehistoryextended       0002=============================*/
/*============database_fixups 0001=============================*/
/*============django_comment_common   0003=============================*/
/*============django_comment_common   0004=============================*/
/*============edxval  0003=============================*/
BEGIN;
ALTER TABLE `edxval_coursevideo` ADD COLUMN `is_hidden` bool DEFAULT 0 NOT NULL;
ALTER TABLE `edxval_coursevideo` ALTER COLUMN `is_hidden` DROP DEFAULT;
COMMIT;
/*============email_marketing 0003=============================*/
BEGIN;
ALTER TABLE `email_marketing_emailmarketingconfiguration` ADD COLUMN `sailthru_lms_url_override` varchar(80) NOT NULL;
COMMIT;
/*============enterprise      0001=============================*/
BEGIN;
CREATE TABLE `enterprise_enterprisecustomer` (`created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `uuid` char(32) NOT NULL PRIMARY KEY, `name` varchar(255) NOT NULL, `active` bool NOT NULL);
CREATE TABLE `enterprise_enterprisecustomeruser` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `user_id` integer UNSIGNED NOT NULL, `enterprise_customer_id` char(32) NOT NULL);
CREATE TABLE `enterprise_historicalenterprisecustomer` (`created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `uuid` char(32) NOT NULL, `name` varchar(255) NOT NULL, `active` bool NOT NULL, `history_id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `history_date` datetime(6) NOT NULL, `history_type` varchar(1) NOT NULL, `history_user_id` integer NULL);
ALTER TABLE `enterprise_enterprisecustomeruser` ADD CONSTRAINT `enterprise_enterpri_enterprise_customer_id_257cf08ca29bc48b_uniq` UNIQUE (`enterprise_customer_id`, `user_id`);
ALTER TABLE `enterprise_enterprisecustomeruser` ADD CONSTRAINT `D38bb8d455e64dd8470b7606517efded` FOREIGN KEY (`enterprise_customer_id`) REFERENCES `enterprise_enterprisecustomer` (`uuid`);
ALTER TABLE `enterprise_historicalenterprisecustomer` ADD CONSTRAINT `enterprise_hist_history_user_id_2938dabbace21ece_fk_auth_user_id` FOREIGN KEY (`history_user_id`) REFERENCES `auth_user` (`id`);
CREATE INDEX `enterprise_historicalenterprisecustomer_ef7c876f` ON `enterprise_historicalenterprisecustomer` (`uuid`);
COMMIT;
/*============enterprise      0002=============================*/
BEGIN;
CREATE TABLE `enterprise_enterprisecustomerbrandingconfiguration` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `logo` varchar(255) NULL, `enterprise_customer_id` char(32) NOT NULL UNIQUE);
ALTER TABLE `enterprise_enterprisecustomerbrandingconfiguration` ADD CONSTRAINT `D1fbd8b8ab06c9a5efdee961a7a75e55` FOREIGN KEY (`enterprise_customer_id`) REFERENCES `enterprise_enterprisecustomer` (`uuid`);
COMMIT;
/*============enterprise      0003=============================*/
BEGIN;
ALTER TABLE `enterprise_enterprisecustomer` ADD COLUMN `site_id` integer DEFAULT 1 NOT NULL;
ALTER TABLE `enterprise_enterprisecustomer` ALTER COLUMN `site_id` DROP DEFAULT;
ALTER TABLE `enterprise_historicalenterprisecustomer` ADD COLUMN `site_id` integer NULL;
ALTER TABLE `enterprise_historicalenterprisecustomer` ALTER COLUMN `site_id` DROP DEFAULT;
ALTER TABLE `enterprise_enterprisecustomerbrandingconfiguration` DROP FOREIGN KEY `D1fbd8b8ab06c9a5efdee961a7a75e55`;
ALTER TABLE `enterprise_enterprisecustomerbrandingconfiguration` ADD CONSTRAINT `D1fbd8b8ab06c9a5efdee961a7a75e55` FOREIGN KEY (`enterprise_customer_id`) REFERENCES `enterprise_enterprisecustomer` (`uuid`);
CREATE INDEX `enterprise_enterprisecustomer_9365d6e7` ON `enterprise_enterprisecustomer` (`site_id`);
ALTER TABLE `enterprise_enterprisecustomer` ADD CONSTRAINT `enterprise_enterprise_site_id_41ce54c2601930cd_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`);
CREATE INDEX `enterprise_historicalenterprisecustomer_9365d6e7` ON `enterprise_historicalenterprisecustomer` (`site_id`);
COMMIT;
/*============enterprise      0004=============================*/
BEGIN;
ALTER TABLE `enterprise_enterprisecustomer` ADD COLUMN `identity_provider` varchar(50) NULL;
ALTER TABLE `enterprise_historicalenterprisecustomer` ADD COLUMN `identity_provider` varchar(50) NULL;
CREATE INDEX `enterprise_enterprisecustomer_ee87fd43` ON `enterprise_enterprisecustomer` (`identity_provider`);
CREATE INDEX `enterprise_historicalenterprisecustomer_ee87fd43` ON `enterprise_historicalenterprisecustomer` (`identity_provider`);
COMMIT;
/*============enterprise      0005=============================*/
BEGIN;
CREATE TABLE `enterprise_pendingenterprisecustomeruser` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `user_email` varchar(254) NOT NULL, `enterprise_customer_id` char(32) NOT NULL);
ALTER TABLE `enterprise_pendingenterprisecustomeruser` ADD CONSTRAINT `D0f27fd26a677554e54740cfe1555271` FOREIGN KEY (`enterprise_customer_id`) REFERENCES `enterprise_enterprisecustomer` (`uuid`);
COMMIT;
/*============enterprise      0006=============================*/
BEGIN;
ALTER TABLE `enterprise_pendingenterprisecustomeruser` ADD CONSTRAINT `enterprise_pendingenterprisecus_user_email_1838ab42a578cf3c_uniq` UNIQUE (`user_email`);
COMMIT;
/*============enterprise      0007=============================*/
BEGIN;
ALTER TABLE `enterprise_enterprisecustomer` ADD COLUMN `catalog` integer UNSIGNED NULL;
ALTER TABLE `enterprise_enterprisecustomer` ALTER COLUMN `catalog` DROP DEFAULT;
ALTER TABLE `enterprise_historicalenterprisecustomer` ADD COLUMN `catalog` integer UNSIGNED NULL;
ALTER TABLE `enterprise_historicalenterprisecustomer` ALTER COLUMN `catalog` DROP DEFAULT;
COMMIT;
/*============enterprise      0008=============================*/
BEGIN;
CREATE TABLE `enterprise_enterprisecustomeridentityprovider` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `provider_id` varchar(50) NOT NULL UNIQUE);
ALTER TABLE `enterprise_enterprisecustomer` DROP COLUMN `identity_provider` CASCADE;
ALTER TABLE `enterprise_historicalenterprisecustomer` DROP COLUMN `identity_provider` CASCADE;
ALTER TABLE `enterprise_enterprisecustomeridentityprovider` ADD COLUMN `enterprise_customer_id` char(32) NOT NULL UNIQUE;
ALTER TABLE `enterprise_enterprisecustomeridentityprovider` ALTER COLUMN `enterprise_customer_id` DROP DEFAULT;
ALTER TABLE `enterprise_enterprisecustomeridentityprovider` ADD CONSTRAINT `D76e394d5748d37ad29b7fd9ad04ea75` FOREIGN KEY (`enterprise_customer_id`) REFERENCES `enterprise_enterprisecustomer` (`uuid`);
COMMIT;
/*============enterprise      0009=============================*/
BEGIN;
CREATE TABLE `enterprise_historicaluserdatasharingconsentaudit` (`id` integer NOT NULL, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `state` varchar(8) NOT NULL, `history_id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `history_date` datetime(6) NOT NULL, `history_type` varchar(1) NOT NULL, `history_user_id` integer NULL, `user_id` integer NULL);
CREATE TABLE `enterprise_userdatasharingconsentaudit` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `state` varchar(8) NOT NULL, `user_id` integer NOT NULL);
ALTER TABLE `enterprise_enterprisecustomer` ADD COLUMN `enable_data_sharing_consent` bool NOT NULL;
ALTER TABLE `enterprise_enterprisecustomer` ADD COLUMN `enforce_data_sharing_consent` varchar(25) NOT NULL;
ALTER TABLE `enterprise_historicalenterprisecustomer` ADD COLUMN `enable_data_sharing_consent` bool NOT NULL;
ALTER TABLE `enterprise_historicalenterprisecustomer` ADD COLUMN `enforce_data_sharing_consent` varchar(25) NOT NULL;
ALTER TABLE `enterprise_historicaluserdatasharingconsentaudit` ADD CONSTRAINT `enterprise_hist_history_user_id_4571f12e73d38294_fk_auth_user_id` FOREIGN KEY (`history_user_id`) REFERENCES `auth_user` (`id`);
CREATE INDEX `enterprise_historicaluserdatasharingconsentaudit_b80bb774` ON `enterprise_historicaluserdatasharingconsentaudit` (`id`);
ALTER TABLE `enterprise_userdatasharingconsentaudit` ADD CONSTRAINT `D7bcf2c6862faec34623e29b1c5e5b5a` FOREIGN KEY (`user_id`) REFERENCES `enterprise_enterprisecustomeruser` (`id`);
COMMIT;
/*============grades  0001=============================*/
BEGIN;
CREATE TABLE `grades_persistentsubsectiongrade` (`created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `id` bigint UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY, `user_id` integer NOT NULL, `course_id` varchar(255) NOT NULL, `usage_key` varchar(255) NOT NULL, `subtree_edited_date` datetime(6) NOT NULL, `course_version` varchar(255) NOT NULL, `earned_all` double precision NOT NULL, `possible_all` double precision NOT NULL, `earned_graded` double precision NOT NULL, `possible_graded` double precision NOT NULL);
CREATE TABLE `grades_visibleblocks` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `blocks_json` longtext NOT NULL, `hashed` varchar(100) NOT NULL UNIQUE);
ALTER TABLE `grades_persistentsubsectiongrade` ADD COLUMN `visible_blocks_hash` varchar(100) NOT NULL;
ALTER TABLE `grades_persistentsubsectiongrade` ALTER COLUMN `visible_blocks_hash` DROP DEFAULT;
ALTER TABLE `grades_persistentsubsectiongrade` ADD CONSTRAINT `grades_persistentsubsectiongrade_course_id_5e423f1e9b6c031_uniq` UNIQUE (`course_id`, `user_id`, `usage_key`);
CREATE INDEX `grades_persistentsubsectiongrade_2ddf9ac4` ON `grades_persistentsubsectiongrade` (`visible_blocks_hash`);
ALTER TABLE `grades_persistentsubsectiongrade` ADD CONSTRAINT `a6bafd85579f2eb43880453893b251a3` FOREIGN KEY (`visible_blocks_hash`) REFERENCES `grades_visibleblocks` (`hashed`);
COMMIT;
/*============grades  0002=============================*/
BEGIN;
ALTER TABLE `grades_persistentsubsectiongrade` CHANGE `subtree_edited_date` `subtree_edited_timestamp` datetime(6) NOT NULL;
COMMIT;
/*============grades  0003=============================*/
BEGIN;
CREATE TABLE `grades_coursepersistentgradesflag` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `course_id` varchar(255) NOT NULL UNIQUE, `changed_by_id` integer NULL);
CREATE TABLE `grades_persistentgradesenabledflag` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `enabled_for_all_courses` bool NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `grades_coursepersistentgradesflag` ADD CONSTRAINT `grades_coursepers_changed_by_id_38bec876127ebacc_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);
ALTER TABLE `grades_persistentgradesenabledflag` ADD CONSTRAINT `grades_persistent_changed_by_id_2350d66400243149_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);
DROP INDEX `course_id` ON `grades_coursepersistentgradesflag`;
COMMIT;
/*============grades  0004=============================*/
BEGIN;
ALTER TABLE `grades_visibleblocks` ADD COLUMN `course_id` varchar(255) NOT NULL;
CREATE INDEX `grades_visibleblocks_ea134da7` ON `grades_visibleblocks` (`course_id`);
COMMIT;
/*============grades  0005=============================*/
/*============grades  0006=============================*/
BEGIN;
CREATE TABLE `grades_persistentcoursegrade` (`created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `id` bigint UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY, `user_id` integer NOT NULL, `course_id` varchar(255) NOT NULL, `course_edited_timestamp` datetime(6) NOT NULL, `course_version` varchar(255) NOT NULL, `grading_policy_hash` varchar(255) NOT NULL, `percent_grade` double precision NOT NULL, `letter_grade` varchar(255) NOT NULL);
ALTER TABLE `grades_persistentcoursegrade` ADD CONSTRAINT `grades_persistentcoursegrade_course_id_6c83398a6a9c0872_uniq` UNIQUE (`course_id`, `user_id`);
CREATE INDEX `grades_persistentcoursegrade_e8701ad4` ON `grades_persistentcoursegrade` (`user_id`);
COMMIT;
/*============grades  0007=============================*/
BEGIN;
ALTER TABLE `grades_persistentcoursegrade` ADD COLUMN `passed_timestamp` datetime(6) NULL;
ALTER TABLE `grades_persistentcoursegrade` ALTER COLUMN `passed_timestamp` DROP DEFAULT;
CREATE INDEX `grades_persistentcoursegra_passed_timestamp_38d17e3e3bc3cb7f_idx` ON `grades_persistentcoursegrade` (`passed_timestamp`, `course_id`);
COMMIT;
/*============grades  0008=============================*/
BEGIN;
ALTER TABLE `grades_persistentsubsectiongrade` ADD COLUMN `first_attempted` datetime(6) NULL;
ALTER TABLE `grades_persistentsubsectiongrade` ALTER COLUMN `first_attempted` DROP DEFAULT;
COMMIT;
/*============oauth2  0004=============================*/
BEGIN;
CREATE INDEX `oauth2_grant_client_id_7f83b952b3c51985_idx` ON `oauth2_grant` (`client_id`, `code`, `expires`);
COMMIT;
/*============oauth_dispatch  0001=============================*/
BEGIN;
CREATE TABLE `oauth_dispatch_restrictedapplication` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `application_id` integer NOT NULL);
ALTER TABLE `oauth_dispatch_restrictedapplication` ADD CONSTRAINT `d0faf25b802e0044a322123f797a61c7` FOREIGN KEY (`application_id`) REFERENCES `oauth2_provider_application` (`id`);
COMMIT;
/*============programs        0009=============================*/
BEGIN;
ALTER TABLE `programs_programsapiconfig` ADD COLUMN `marketing_path` varchar(255) NOT NULL;
COMMIT;
/*============student 0007=============================*/
BEGIN;
CREATE TABLE `student_registrationcookieconfiguration` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `utm_cookie_name` varchar(255) NOT NULL, `affiliate_cookie_name` varchar(255) NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `student_registrationcookieconfiguration` ADD CONSTRAINT `student_registrati_changed_by_id_7c813444cd41f76_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);
COMMIT;
/*============student 0008=============================*/
/*============third_party_auth        0003=============================*/
BEGIN;
ALTER TABLE `third_party_auth_samlproviderconfig` ADD COLUMN `debug_mode` bool NOT NULL;
COMMIT;
/*============third_party_auth        0004=============================*/
BEGIN;
ALTER TABLE `third_party_auth_ltiproviderconfig` ADD COLUMN `visible` bool NOT NULL;
ALTER TABLE `third_party_auth_oauth2providerconfig` ADD COLUMN `visible` bool NOT NULL;
ALTER TABLE `third_party_auth_samlproviderconfig` ADD COLUMN `visible` bool NOT NULL;
COMMIT;
/*============third_party_auth        0005=============================*/
BEGIN;
ALTER TABLE `third_party_auth_oauth2providerconfig` ADD COLUMN `provider_slug` varchar(30) NOT NULL;
ALTER TABLE `third_party_auth_ltiproviderconfig` ADD COLUMN `site_id` integer NOT NULL;
ALTER TABLE `third_party_auth_oauth2providerconfig` ADD COLUMN `site_id` integer NOT NULL;
ALTER TABLE `third_party_auth_samlproviderconfig` ADD COLUMN `site_id` integer NOT NULL;
ALTER TABLE `third_party_auth_samlconfiguration` ADD COLUMN `site_id` integer NOT NULL;
CREATE INDEX `third_party_auth_oauth2providerconfig_24b8e178` ON `third_party_auth_oauth2providerconfig` (`provider_slug`);
CREATE INDEX `third_party_auth_ltiproviderconfig_9365d6e7` ON `third_party_auth_ltiproviderconfig` (`site_id`);
ALTER TABLE `third_party_auth_ltiproviderconfig` ADD CONSTRAINT `third_party_auth_ltip_site_id_30e45357dbe462db_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`);
CREATE INDEX `third_party_auth_oauth2providerconfig_9365d6e7` ON `third_party_auth_oauth2providerconfig` (`site_id`);
ALTER TABLE `third_party_auth_oauth2providerconfig` ADD CONSTRAINT `third_party_auth_oaut_site_id_3f77f0fe311b6f5c_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`);
CREATE INDEX `third_party_auth_samlproviderconfig_9365d6e7` ON `third_party_auth_samlproviderconfig` (`site_id`);
ALTER TABLE `third_party_auth_samlproviderconfig` ADD CONSTRAINT `third_party_auth_saml_site_id_625158ae0a405970_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`);
CREATE INDEX `third_party_auth_samlconfiguration_9365d6e7` ON `third_party_auth_samlconfiguration` (`site_id`);
ALTER TABLE `third_party_auth_samlconfiguration` ADD CONSTRAINT `third_party_auth_saml_site_id_108365f249ed6aac_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`);
COMMIT;
/*============wiki    0004=============================*/
BEGIN;
ALTER TABLE `wiki_urlpath` MODIFY `slug` varchar(255) NULL;
COMMIT;
/*============user_tasks      0001=============================*/
/*============user_tasks      0002=============================*/
BEGIN;
CREATE TABLE `user_tasks_usertaskartifact` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `uuid` char(32) NOT NULL UNIQUE, `name` varchar(255) NOT NULL, `file` varchar(100) NULL, `url` varchar(200) NOT NULL, `text` longtext NOT NULL);
CREATE TABLE `user_tasks_usertaskstatus` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `uuid` char(32) NOT NULL UNIQUE, `task_id` varchar(128) NOT NULL UNIQUE, `is_container` bool NOT NULL, `task_class` varchar(128) NOT NULL, `name` varchar(255) NOT NULL, `state` varchar(128) NOT NULL, `completed_steps` smallint UNSIGNED NOT NULL, `total_steps` smallint UNSIGNED NOT NULL, `attempts` smallint UNSIGNED NOT NULL, `parent_id` integer NULL, `user_id` integer NOT NULL);
ALTER TABLE `user_tasks_usertaskartifact` ADD COLUMN `status_id` integer NOT NULL;
ALTER TABLE `user_tasks_usertaskartifact` ALTER COLUMN `status_id` DROP DEFAULT;
ALTER TABLE `user_tasks_usertaskstatus` ADD CONSTRAINT `user__parent_id_2a1a586c3c2ac2a4_fk_user_tasks_usertaskstatus_id` FOREIGN KEY (`parent_id`) REFERENCES `user_tasks_usertaskstatus` (`id`);
ALTER TABLE `user_tasks_usertaskstatus` ADD CONSTRAINT `user_tasks_usertaskstat_user_id_5ceae753d027017b_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);
CREATE INDEX `user_tasks_usertaskartifact_dc91ed4b` ON `user_tasks_usertaskartifact` (`status_id`);
ALTER TABLE `user_tasks_usertaskartifact` ADD CONSTRAINT `user__status_id_265997facac95070_fk_user_tasks_usertaskstatus_id` FOREIGN KEY (`status_id`) REFERENCES `user_tasks_usertaskstatus` (`id`);
COMMIT;


/* Current Database: programs */
BEGIN;
CREATE DATABASE IF NOT EXISTS `programs` DEFAULT CHARACTER SET utf8;
USE `programs`;

DROP TABLE IF EXISTS `auth_group`;
CREATE TABLE `auth_group` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
);

LOCK TABLES `auth_group` WRITE;
INSERT INTO `auth_group` VALUES (3,'Admins'),(2,'Authors'),(1,'Learners');
UNLOCK TABLES;

DROP TABLE IF EXISTS `django_content_type`;
CREATE TABLE `django_content_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_label` varchar(100) NOT NULL,
  `model` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `django_content_type_app_label_45f3b1d93ec8c61c_uniq` (`app_label`,`model`)
);

LOCK TABLES `django_content_type` WRITE;
INSERT INTO `django_content_type` VALUES (1,'admin','logentry'),(3,'auth','group'),(2,'auth','permission'),(4,'contenttypes','contenttype'),(11,'core','user'),(6,'corsheaders','corsmodel'),(15,'programs','coursecode'),(13,'programs','organization'),(12,'programs','program'),(16,'programs','programcoursecode'),(17,'programs','programcourserunmode'),(18,'programs','programdefault'),(14,'programs','programorganization'),(5,'sessions','session'),(9,'social_auth','association'),(10,'social_auth','code'),(8,'social_auth','nonce'),(7,'social_auth','usersocialauth');
UNLOCK TABLES;

DROP TABLE IF EXISTS `auth_permission`;
CREATE TABLE `auth_permission` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `content_type_id` int(11) NOT NULL,
  `codename` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `content_type_id` (`content_type_id`,`codename`),
  CONSTRAINT `auth__content_type_id_508cf46651277a81_fk_django_content_type_id` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`)
);

DROP TABLE IF EXISTS `auth_group_permissions`;
CREATE TABLE `auth_group_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `group_id` (`group_id`,`permission_id`),
  KEY `auth_group__permission_id_1f49ccbbdc69d2fc_fk_auth_permission_id` (`permission_id`),
  CONSTRAINT `auth_group__permission_id_1f49ccbbdc69d2fc_fk_auth_permission_id` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`),
  CONSTRAINT `auth_group_permission_group_id_689710a9a73b7457_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`)
);

LOCK TABLES `auth_permission` WRITE;
INSERT INTO `auth_permission` VALUES (1,'Can add log entry',1,'add_logentry'),(2,'Can change log entry',1,'change_logentry'),(3,'Can delete log entry',1,'delete_logentry'),(4,'Can add permission',2,'add_permission'),(5,'Can change permission',2,'change_permission'),(6,'Can delete permission',2,'delete_permission'),(7,'Can add group',3,'add_group'),(8,'Can change group',3,'change_group'),(9,'Can delete group',3,'delete_group'),(10,'Can add content type',4,'add_contenttype'),(11,'Can change content type',4,'change_contenttype'),(12,'Can delete content type',4,'delete_contenttype'),(13,'Can add session',5,'add_session'),(14,'Can change session',5,'change_session'),(15,'Can delete session',5,'delete_session'),(16,'Can add cors model',6,'add_corsmodel'),(17,'Can change cors model',6,'change_corsmodel'),(18,'Can delete cors model',6,'delete_corsmodel'),(19,'Can add user social auth',7,'add_usersocialauth'),(20,'Can change user social auth',7,'change_usersocialauth'),(21,'Can delete user social auth',7,'delete_usersocialauth'),(22,'Can add nonce',8,'add_nonce'),(23,'Can change nonce',8,'change_nonce'),(24,'Can delete nonce',8,'delete_nonce'),(25,'Can add association',9,'add_association'),(26,'Can change association',9,'change_association'),(27,'Can delete association',9,'delete_association'),(28,'Can add code',10,'add_code'),(29,'Can change code',10,'change_code'),(30,'Can delete code',10,'delete_code'),(31,'Can add user',11,'add_user'),(32,'Can change user',11,'change_user'),(33,'Can delete user',11,'delete_user'),(34,'Can add program',12,'add_program'),(35,'Can change program',12,'change_program'),(36,'Can delete program',12,'delete_program'),(37,'Can add organization',13,'add_organization'),(38,'Can change organization',13,'change_organization'),(39,'Can delete organization',13,'delete_organization'),(40,'Can add program organization',14,'add_programorganization'),(41,'Can change program organization',14,'change_programorganization'),(42,'Can delete program organization',14,'delete_programorganization'),(43,'Can add course code',15,'add_coursecode'),(44,'Can change course code',15,'change_coursecode'),(45,'Can delete course code',15,'delete_coursecode'),(46,'Can add program course code',16,'add_programcoursecode'),(47,'Can change program course code',16,'change_programcoursecode'),(48,'Can delete program course code',16,'delete_programcoursecode'),(49,'Can add program course run mode',17,'add_programcourserunmode'),(50,'Can change program course run mode',17,'change_programcourserunmode'),(51,'Can delete program course run mode',17,'delete_programcourserunmode'),(52,'Can add program default',18,'add_programdefault'),(53,'Can change program default',18,'change_programdefault'),(54,'Can delete program default',18,'delete_programdefault');
UNLOCK TABLES;

DROP TABLE IF EXISTS `core_user`;
CREATE TABLE `core_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `password` varchar(128) NOT NULL,
  `last_login` datetime(6) DEFAULT NULL,
  `is_superuser` tinyint(1) NOT NULL,
  `username` varchar(30) NOT NULL,
  `first_name` varchar(30) NOT NULL,
  `last_name` varchar(30) NOT NULL,
  `email` varchar(254) NOT NULL,
  `is_staff` tinyint(1) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `date_joined` datetime(6) NOT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
);

LOCK TABLES `core_user` WRITE;
INSERT INTO `core_user` VALUES (1,'!H6GTvxCOzDEI06bbWX1dJcj6XzAoSvcARBL4a0mm',NULL,0,'credentials_service_user','','','',0,1,'2017-03-01 23:34:19.879450',NULL);
UNLOCK TABLES;

DROP TABLE IF EXISTS `core_user_groups`;
CREATE TABLE `core_user_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`group_id`),
  KEY `core_user_groups_group_id_14904bd68d96192e_fk_auth_group_id` (`group_id`),
  CONSTRAINT `core_user_groups_group_id_14904bd68d96192e_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`),
  CONSTRAINT `core_user_groups_user_id_4c28bfad54a3d1f5_fk_core_user_id` FOREIGN KEY (`user_id`) REFERENCES `core_user` (`id`)
);

DROP TABLE IF EXISTS `core_user_user_permissions`;
CREATE TABLE `core_user_user_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`permission_id`),
  KEY `core_user_u_permission_id_4c265ba1f3aec17b_fk_auth_permission_id` (`permission_id`),
  CONSTRAINT `core_user_u_permission_id_4c265ba1f3aec17b_fk_auth_permission_id` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`),
  CONSTRAINT `core_user_user_permissi_user_id_7060c4db34d389ef_fk_core_user_id` FOREIGN KEY (`user_id`) REFERENCES `core_user` (`id`)
);

DROP TABLE IF EXISTS `corsheaders_corsmodel`;
CREATE TABLE `corsheaders_corsmodel` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cors` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `django_admin_log`;
CREATE TABLE `django_admin_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `action_time` datetime(6) NOT NULL,
  `object_id` longtext,
  `object_repr` varchar(200) NOT NULL,
  `action_flag` smallint(5) unsigned NOT NULL,
  `change_message` longtext NOT NULL,
  `content_type_id` int(11) DEFAULT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `djang_content_type_id_697914295151027a_fk_django_content_type_id` (`content_type_id`),
  KEY `django_admin_log_user_id_52fdd58701c5f563_fk_core_user_id` (`user_id`),
  CONSTRAINT `djang_content_type_id_697914295151027a_fk_django_content_type_id` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`),
  CONSTRAINT `django_admin_log_user_id_52fdd58701c5f563_fk_core_user_id` FOREIGN KEY (`user_id`) REFERENCES `core_user` (`id`)
);

DROP TABLE IF EXISTS `django_migrations`;
CREATE TABLE `django_migrations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `applied` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
);

LOCK TABLES `django_migrations` WRITE;
INSERT INTO `django_migrations` VALUES (1,'contenttypes','0001_initial','2017-03-01 23:34:15.143491'),(2,'contenttypes','0002_remove_content_type_name','2017-03-01 23:34:15.581585'),(3,'auth','0001_initial','2017-03-01 23:34:17.001710'),(4,'auth','0002_alter_permission_name_max_length','2017-03-01 23:34:17.314840'),(5,'auth','0003_alter_user_email_max_length','2017-03-01 23:34:17.353492'),(6,'auth','0004_alter_user_username_opts','2017-03-01 23:34:17.388098'),(7,'auth','0005_alter_user_last_login_null','2017-03-01 23:34:17.420937'),(8,'auth','0006_require_contenttypes_0002','2017-03-01 23:34:17.439264'),(9,'core','0001_initial','2017-03-01 23:34:19.050330'),(10,'admin','0001_initial','2017-03-01 23:34:19.862609'),(11,'core','0002_add_credentials_service_user','2017-03-01 23:34:19.909096'),(12,'programs','0001_initial','2017-03-01 23:34:23.520253'),(13,'programs','0002_create_groups','2017-03-01 23:34:23.583041'),(14,'programs','0003_program_marketing_slug','2017-03-01 23:34:23.879837'),(15,'programs','0004_start_date_run_key','2017-03-01 23:34:24.414794'),(16,'programs','0005_auto_20151204_2212','2017-03-01 23:34:24.769350'),(17,'programs','0006_auto_20160104_1920','2017-03-01 23:34:26.394501'),(18,'programs','0007_auto_20160318_1859','2017-03-01 23:34:27.007302'),(19,'programs','0008_auto_20160419_1449','2017-03-01 23:34:27.440005'),(20,'programs','0009_make_program_uuid_unique','2017-03-01 23:34:27.644112'),(21,'programs','0010_programdefault','2017-03-01 23:34:27.817764'),(22,'programs','0011_auto_20160510_1524','2017-03-01 23:34:27.940440'),(23,'programs','0012_auto_20160719_1523','2017-03-01 23:34:27.979252'),(24,'programs','0013_auto_20160725_2147','2017-03-01 23:34:28.023517'),(25,'sessions','0001_initial','2017-03-01 23:34:28.317377'),(26,'default','0001_initial','2017-03-01 23:34:29.689212'),(27,'default','0002_add_related_name','2017-03-01 23:34:30.111381'),(28,'default','0003_alter_email_max_length','2017-03-01 23:34:30.486537'),(29,'default','0004_auto_20160423_0400','2017-03-01 23:34:30.540123'),(30,'social_auth','0005_auto_20160727_2333','2017-03-01 23:34:30.674307'),(31,'social_auth','0001_initial','2017-03-01 23:34:30.710207'),(32,'social_auth','0003_alter_email_max_length','2017-03-01 23:34:30.736053'),(33,'social_auth','0004_auto_20160423_0400','2017-03-01 23:34:30.751432'),(34,'social_auth','0002_add_related_name','2017-03-01 23:34:30.766840');
UNLOCK TABLES;

DROP TABLE IF EXISTS `django_session`;
CREATE TABLE `django_session` (
  `session_key` varchar(40) NOT NULL,
  `session_data` longtext NOT NULL,
  `expire_date` datetime(6) NOT NULL,
  PRIMARY KEY (`session_key`),
  KEY `django_session_de54fa62` (`expire_date`)
);

DROP TABLE IF EXISTS `programs_organization`;
CREATE TABLE `programs_organization` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  `key` varchar(64) NOT NULL,
  `display_name` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `key` (`key`)
);

DROP TABLE IF EXISTS `programs_coursecode`;
CREATE TABLE `programs_coursecode` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  `key` varchar(64) NOT NULL,
  `display_name` varchar(128) NOT NULL,
  `organization_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `programs_coursecode_organization_id_4dfbf05d82344b73_uniq` (`organization_id`,`key`),
  KEY `programs_coursecode_26b2345e` (`organization_id`),
  CONSTRAINT `pro_organization_id_647c6b90cb2cb326_fk_programs_organization_id` FOREIGN KEY (`organization_id`) REFERENCES `programs_organization` (`id`)
);

DROP TABLE IF EXISTS `programs_program`;
CREATE TABLE `programs_program` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  `name` varchar(255) NOT NULL,
  `subtitle` varchar(255) NOT NULL,
  `category` varchar(32) NOT NULL,
  `status` varchar(24) NOT NULL,
  `marketing_slug` varchar(255) NOT NULL,
  `banner_image` varchar(1000) DEFAULT NULL,
  `uuid` char(32) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `programs_program_uuid_50669517a058450a_uniq` (`uuid`),
  KEY `programs_program_status_580c5ce5b359dfea_idx` (`status`,`category`)
);

DROP TABLE IF EXISTS `programs_programcoursecode`;
CREATE TABLE `programs_programcoursecode` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  `position` int(11) NOT NULL,
  `course_code_id` int(11) NOT NULL,
  `program_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `programs_programcoursecode_program_id_5543af22af5a4c51_uniq` (`program_id`,`position`),
  KEY `progra_course_code_id_735cf886d0987c98_fk_programs_coursecode_id` (`course_code_id`),
  CONSTRAINT `progra_course_code_id_735cf886d0987c98_fk_programs_coursecode_id` FOREIGN KEY (`course_code_id`) REFERENCES `programs_coursecode` (`id`),
  CONSTRAINT `programs_prog_program_id_4fc9056566e1d58b_fk_programs_program_id` FOREIGN KEY (`program_id`) REFERENCES `programs_program` (`id`)
);

DROP TABLE IF EXISTS `programs_programcourserunmode`;
CREATE TABLE `programs_programcourserunmode` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  `lms_url` varchar(1024) NOT NULL,
  `course_key` varchar(255) NOT NULL,
  `mode_slug` varchar(64) NOT NULL,
  `sku` varchar(255) NOT NULL,
  `program_course_code_id` int(11) NOT NULL,
  `run_key` varchar(255) NOT NULL,
  `start_date` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `programs_programcou_program_course_code_id_707ad4bd0aa0c951_uniq` (`program_course_code_id`,`course_key`,`mode_slug`,`sku`),
  CONSTRAINT `D8cca5c3079795bace927686a42a5cb3` FOREIGN KEY (`program_course_code_id`) REFERENCES `programs_programcoursecode` (`id`)
);

DROP TABLE IF EXISTS `programs_programdefault`;
CREATE TABLE `programs_programdefault` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `banner_image` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `programs_programorganization`;
CREATE TABLE `programs_programorganization` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  `organization_id` int(11) NOT NULL,
  `program_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `pro_organization_id_73beeb4010c628d4_fk_programs_organization_id` (`organization_id`),
  KEY `programs_prog_program_id_4bb48f49a79a7556_fk_programs_program_id` (`program_id`),
  CONSTRAINT `pro_organization_id_73beeb4010c628d4_fk_programs_organization_id` FOREIGN KEY (`organization_id`) REFERENCES `programs_organization` (`id`),
  CONSTRAINT `programs_prog_program_id_4bb48f49a79a7556_fk_programs_program_id` FOREIGN KEY (`program_id`) REFERENCES `programs_program` (`id`)
);

DROP TABLE IF EXISTS `social_auth_association`;
CREATE TABLE `social_auth_association` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_url` varchar(255) NOT NULL,
  `handle` varchar(255) NOT NULL,
  `secret` varchar(255) NOT NULL,
  `issued` int(11) NOT NULL,
  `lifetime` int(11) NOT NULL,
  `assoc_type` varchar(64) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `social_auth_association_server_url_17bf7e87f2968244_uniq` (`server_url`,`handle`)
);

DROP TABLE IF EXISTS `social_auth_code`;
CREATE TABLE `social_auth_code` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(254) NOT NULL,
  `code` varchar(32) NOT NULL,
  `verified` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `social_auth_code_email_75f27066d057e3b6_uniq` (`email`,`code`),
  KEY `social_auth_code_c1336794` (`code`)
);

DROP TABLE IF EXISTS `social_auth_nonce`;
CREATE TABLE `social_auth_nonce` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_url` varchar(255) NOT NULL,
  `timestamp` int(11) NOT NULL,
  `salt` varchar(65) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `social_auth_nonce_server_url_36601f978463b4_uniq` (`server_url`,`timestamp`,`salt`)
);

DROP TABLE IF EXISTS `social_auth_usersocialauth`;
CREATE TABLE `social_auth_usersocialauth` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `provider` varchar(32) NOT NULL,
  `uid` varchar(255) NOT NULL,
  `extra_data` longtext NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `social_auth_usersocialauth_provider_2f763109e2c4a1fb_uniq` (`provider`,`uid`),
  KEY `social_auth_usersociala_user_id_193b2d80880502b2_fk_core_user_id` (`user_id`),
  CONSTRAINT `social_auth_usersociala_user_id_193b2d80880502b2_fk_core_user_id` FOREIGN KEY (`user_id`) REFERENCES `core_user` (`id`)
);
COMMIT;

