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



/* Current Database: dashboard */
BEGIN;
CREATE DATABASE IF NOT EXISTS `dashboard` DEFAULT CHARACTER SET utf8;
USE `dashboard`;

DROP TABLE IF EXISTS `analytics_dashboard_user`;
CREATE TABLE `analytics_dashboard_user` (
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
  `language` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
);

DROP TABLE IF EXISTS `auth_group`;
CREATE TABLE `auth_group` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
);

DROP TABLE IF EXISTS `analytics_dashboard_user_groups`;
CREATE TABLE `analytics_dashboard_user_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `analytics_dashboard_user_groups_user_id_4bab38f4_uniq` (`user_id`,`group_id`),
  KEY `analytics_dashboard_user_grou_group_id_8a812370_fk_auth_group_id` (`group_id`),
  CONSTRAINT `analytics_dashbo_user_id_46bb902b_fk_analytics_dashboard_user_id` FOREIGN KEY (`user_id`) REFERENCES `analytics_dashboard_user` (`id`),
  CONSTRAINT `analytics_dashboard_user_grou_group_id_8a812370_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`)
);

DROP TABLE IF EXISTS `django_content_type`;
CREATE TABLE `django_content_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_label` varchar(100) NOT NULL,
  `model` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `django_content_type_app_label_76bd3d3b_uniq` (`app_label`,`model`)
);

DROP TABLE IF EXISTS `auth_permission`;
CREATE TABLE `auth_permission` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `content_type_id` int(11) NOT NULL,
  `codename` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_permission_content_type_id_01ab375a_uniq` (`content_type_id`,`codename`),
  CONSTRAINT `auth_permissi_content_type_id_2f476e4b_fk_django_content_type_id` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`)
);

DROP TABLE IF EXISTS `analytics_dashboard_user_user_permissions`;
CREATE TABLE `analytics_dashboard_user_user_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `analytics_dashboard_user_user_permissions_user_id_8fc83162_uniq` (`user_id`,`permission_id`),
  KEY `analytics_dashboard_permission_id_d944e976_fk_auth_permission_id` (`permission_id`),
  CONSTRAINT `analytics_dashbo_user_id_399b0386_fk_analytics_dashboard_user_id` FOREIGN KEY (`user_id`) REFERENCES `analytics_dashboard_user` (`id`),
  CONSTRAINT `analytics_dashboard_permission_id_d944e976_fk_auth_permission_id` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`)
);

DROP TABLE IF EXISTS `announcements_announcement`;
CREATE TABLE `announcements_announcement` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(50) NOT NULL,
  `content` longtext NOT NULL,
  `creation_date` datetime(6) NOT NULL,
  `site_wide` tinyint(1) NOT NULL,
  `members_only` tinyint(1) NOT NULL,
  `dismissal_type` int(11) NOT NULL,
  `publish_start` datetime(6) NOT NULL,
  `publish_end` datetime(6) DEFAULT NULL,
  `creator_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `announcements_creator_id_d9be5764_fk_analytics_dashboard_user_id` (`creator_id`),
  CONSTRAINT `announcements_creator_id_d9be5764_fk_analytics_dashboard_user_id` FOREIGN KEY (`creator_id`) REFERENCES `analytics_dashboard_user` (`id`)
);

DROP TABLE IF EXISTS `announcements_dismissal`;
CREATE TABLE `announcements_dismissal` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dismissed_at` datetime(6) NOT NULL,
  `announcement_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `announ_announcement_id_719fe978_fk_announcements_announcement_id` (`announcement_id`),
  KEY `announcements_di_user_id_927879ee_fk_analytics_dashboard_user_id` (`user_id`),
  CONSTRAINT `announ_announcement_id_719fe978_fk_announcements_announcement_id` FOREIGN KEY (`announcement_id`) REFERENCES `announcements_announcement` (`id`),
  CONSTRAINT `announcements_di_user_id_927879ee_fk_analytics_dashboard_user_id` FOREIGN KEY (`user_id`) REFERENCES `analytics_dashboard_user` (`id`)
);

DROP TABLE IF EXISTS `auth_group_permissions`;
CREATE TABLE `auth_group_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_group_permissions_group_id_0cd325b0_uniq` (`group_id`,`permission_id`),
  KEY `auth_group_permissi_permission_id_84c5c92e_fk_auth_permission_id` (`permission_id`),
  CONSTRAINT `auth_group_permissi_permission_id_84c5c92e_fk_auth_permission_id` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`),
  CONSTRAINT `auth_group_permissions_group_id_b120cbf9_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`)
);

LOCK TABLES `django_content_type` WRITE;
INSERT INTO `django_content_type` VALUES (6,'admin','logentry'),(10,'announcements','announcement'),(11,'announcements','dismissal'),(2,'auth','group'),(1,'auth','permission'),(3,'contenttypes','contenttype'),(12,'core','user'),(16,'default','association'),(17,'default','code'),(15,'default','nonce'),(14,'default','usersocialauth'),(4,'sessions','session'),(5,'sites','site'),(13,'soapbox','message'),(7,'waffle','flag'),(9,'waffle','sample'),(8,'waffle','switch');
UNLOCK TABLES;

LOCK TABLES `auth_permission` WRITE;
INSERT INTO `auth_permission` VALUES (1,'Can add permission',1,'add_permission'),(2,'Can change permission',1,'change_permission'),(3,'Can delete permission',1,'delete_permission'),(4,'Can add group',2,'add_group'),(5,'Can change group',2,'change_group'),(6,'Can delete group',2,'delete_group'),(7,'Can add content type',3,'add_contenttype'),(8,'Can change content type',3,'change_contenttype'),(9,'Can delete content type',3,'delete_contenttype'),(10,'Can add session',4,'add_session'),(11,'Can change session',4,'change_session'),(12,'Can delete session',4,'delete_session'),(13,'Can add site',5,'add_site'),(14,'Can change site',5,'change_site'),(15,'Can delete site',5,'delete_site'),(16,'Can add log entry',6,'add_logentry'),(17,'Can change log entry',6,'change_logentry'),(18,'Can delete log entry',6,'delete_logentry'),(19,'Can add flag',7,'add_flag'),(20,'Can change flag',7,'change_flag'),(21,'Can delete flag',7,'delete_flag'),(22,'Can add switch',8,'add_switch'),(23,'Can change switch',8,'change_switch'),(24,'Can delete switch',8,'delete_switch'),(25,'Can add sample',9,'add_sample'),(26,'Can change sample',9,'change_sample'),(27,'Can delete sample',9,'delete_sample'),(28,'Can add announcement',10,'add_announcement'),(29,'Can change announcement',10,'change_announcement'),(30,'Can delete announcement',10,'delete_announcement'),(31,'Can add dismissal',11,'add_dismissal'),(32,'Can change dismissal',11,'change_dismissal'),(33,'Can delete dismissal',11,'delete_dismissal'),(34,'Can add user',12,'add_user'),(35,'Can change user',12,'change_user'),(36,'Can delete user',12,'delete_user'),(37,'Can add message',13,'add_message'),(38,'Can change message',13,'change_message'),(39,'Can delete message',13,'delete_message'),(40,'Can add user social auth',14,'add_usersocialauth'),(41,'Can change user social auth',14,'change_usersocialauth'),(42,'Can delete user social auth',14,'delete_usersocialauth'),(43,'Can add nonce',15,'add_nonce'),(44,'Can change nonce',15,'change_nonce'),(45,'Can delete nonce',15,'delete_nonce'),(46,'Can add association',16,'add_association'),(47,'Can change association',16,'change_association'),(48,'Can delete association',16,'delete_association'),(49,'Can add code',17,'add_code'),(50,'Can change code',17,'change_code'),(51,'Can delete code',17,'delete_code');
UNLOCK TABLES;

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
  KEY `django_admin__content_type_id_c4bce8eb_fk_django_content_type_id` (`content_type_id`),
  KEY `django_admin_log_user_id_c564eba6_fk_analytics_dashboard_user_id` (`user_id`),
  CONSTRAINT `django_admin__content_type_id_c4bce8eb_fk_django_content_type_id` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`),
  CONSTRAINT `django_admin_log_user_id_c564eba6_fk_analytics_dashboard_user_id` FOREIGN KEY (`user_id`) REFERENCES `analytics_dashboard_user` (`id`)
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
INSERT INTO `django_migrations` VALUES (1,'contenttypes','0001_initial','2017-03-01 23:38:42.330328'),(2,'auth','0001_initial','2017-03-01 23:38:44.300841'),(3,'core','0001_initial','2017-03-01 23:38:46.299604'),(4,'admin','0001_initial','2017-03-01 23:38:47.033507'),(5,'admin','0002_logentry_remove_auto_add','2017-03-01 23:38:47.096921'),(6,'announcements','0001_initial','2017-03-01 23:38:48.410435'),(7,'contenttypes','0002_remove_content_type_name','2017-03-01 23:38:48.896721'),(8,'auth','0002_alter_permission_name_max_length','2017-03-01 23:38:49.253765'),(9,'auth','0003_alter_user_email_max_length','2017-03-01 23:38:49.287575'),(10,'auth','0004_alter_user_username_opts','2017-03-01 23:38:49.342417'),(11,'auth','0005_alter_user_last_login_null','2017-03-01 23:38:49.389706'),(12,'auth','0006_require_contenttypes_0002','2017-03-01 23:38:49.412993'),(13,'auth','0007_alter_validators_add_error_messages','2017-03-01 23:38:49.459825'),(14,'core','0002_auto_20160729_1156','2017-03-01 23:38:50.799990'),(15,'core','0003_auto_20160801_1741','2017-03-01 23:38:50.863646'),(16,'default','0001_initial','2017-03-01 23:38:52.158465'),(17,'default','0002_add_related_name','2017-03-01 23:38:52.550976'),(18,'default','0003_alter_email_max_length','2017-03-01 23:38:52.941732'),(19,'default','0004_auto_20160423_0400','2017-03-01 23:38:52.979365'),(20,'sessions','0001_initial','2017-03-01 23:38:53.255611'),(21,'sites','0001_initial','2017-03-01 23:38:53.442912'),(22,'sites','0002_alter_domain_unique','2017-03-01 23:38:53.582678'),(23,'waffle','0001_initial','2017-03-01 23:38:56.050799');
UNLOCK TABLES;

DROP TABLE IF EXISTS `django_session`;
CREATE TABLE `django_session` (
  `session_key` varchar(40) NOT NULL,
  `session_data` longtext NOT NULL,
  `expire_date` datetime(6) NOT NULL,
  PRIMARY KEY (`session_key`),
  KEY `django_session_de54fa62` (`expire_date`)
);

DROP TABLE IF EXISTS `django_site`;
CREATE TABLE `django_site` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain` varchar(100) NOT NULL,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `django_site_domain_a2e37b91_uniq` (`domain`)
);

LOCK TABLES `django_site` WRITE;
INSERT INTO `django_site` VALUES (1,'example.com','example.com');
UNLOCK TABLES;

DROP TABLE IF EXISTS `social_auth_association`;
CREATE TABLE `social_auth_association` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_url` varchar(255) NOT NULL,
  `handle` varchar(255) NOT NULL,
  `secret` varchar(255) NOT NULL,
  `issued` int(11) NOT NULL,
  `lifetime` int(11) NOT NULL,
  `assoc_type` varchar(64) NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `social_auth_code`;
CREATE TABLE `social_auth_code` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(254) NOT NULL,
  `code` varchar(32) NOT NULL,
  `verified` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `social_auth_code_email_801b2d02_uniq` (`email`,`code`),
  KEY `social_auth_code_c1336794` (`code`)
);

DROP TABLE IF EXISTS `social_auth_nonce`;
CREATE TABLE `social_auth_nonce` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_url` varchar(255) NOT NULL,
  `timestamp` int(11) NOT NULL,
  `salt` varchar(65) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `social_auth_nonce_server_url_f6284463_uniq` (`server_url`,`timestamp`,`salt`)
);

DROP TABLE IF EXISTS `social_auth_usersocialauth`;
CREATE TABLE `social_auth_usersocialauth` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `provider` varchar(32) NOT NULL,
  `uid` varchar(255) NOT NULL,
  `extra_data` longtext NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `social_auth_usersocialauth_provider_e6b5e668_uniq` (`provider`,`uid`),
  KEY `social_auth_user_user_id_17d28448_fk_analytics_dashboard_user_id` (`user_id`),
  CONSTRAINT `social_auth_user_user_id_17d28448_fk_analytics_dashboard_user_id` FOREIGN KEY (`user_id`) REFERENCES `analytics_dashboard_user` (`id`)
);

DROP TABLE IF EXISTS `waffle_flag`;
CREATE TABLE `waffle_flag` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `everyone` tinyint(1) DEFAULT NULL,
  `percent` decimal(3,1) DEFAULT NULL,
  `testing` tinyint(1) NOT NULL,
  `superusers` tinyint(1) NOT NULL,
  `staff` tinyint(1) NOT NULL,
  `authenticated` tinyint(1) NOT NULL,
  `languages` longtext NOT NULL,
  `rollout` tinyint(1) NOT NULL,
  `note` longtext NOT NULL,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `waffle_flag_e2fa5388` (`created`)
);

DROP TABLE IF EXISTS `waffle_flag_groups`;
CREATE TABLE `waffle_flag_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `flag_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `waffle_flag_groups_flag_id_8ba0c71b_uniq` (`flag_id`,`group_id`),
  KEY `waffle_flag_groups_group_id_a97c4f66_fk_auth_group_id` (`group_id`),
  CONSTRAINT `waffle_flag_groups_flag_id_c11c0c05_fk_waffle_flag_id` FOREIGN KEY (`flag_id`) REFERENCES `waffle_flag` (`id`),
  CONSTRAINT `waffle_flag_groups_group_id_a97c4f66_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`)
);

DROP TABLE IF EXISTS `waffle_flag_users`;
CREATE TABLE `waffle_flag_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `flag_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `waffle_flag_users_flag_id_b46f76b0_uniq` (`flag_id`,`user_id`),
  KEY `waffle_flag_user_user_id_8026df9b_fk_analytics_dashboard_user_id` (`user_id`),
  CONSTRAINT `waffle_flag_user_user_id_8026df9b_fk_analytics_dashboard_user_id` FOREIGN KEY (`user_id`) REFERENCES `analytics_dashboard_user` (`id`),
  CONSTRAINT `waffle_flag_users_flag_id_833c37b0_fk_waffle_flag_id` FOREIGN KEY (`flag_id`) REFERENCES `waffle_flag` (`id`)
);

DROP TABLE IF EXISTS `waffle_sample`;
CREATE TABLE `waffle_sample` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `percent` decimal(4,1) NOT NULL,
  `note` longtext NOT NULL,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `waffle_sample_e2fa5388` (`created`)
);

DROP TABLE IF EXISTS `waffle_switch`;
CREATE TABLE `waffle_switch` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `active` tinyint(1) NOT NULL,
  `note` longtext NOT NULL,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `waffle_switch_e2fa5388` (`created`)
);
COMMIT;


/* Current Database: programs */
BEGIN
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

/* Database: ecommerce */
BEGIN;
CREATE DATABASE IF NOT EXISTS `ecommerce` DEFAULT CHARACTER SET utf8;
USE `ecommerce`;


DROP TABLE IF EXISTS `address_country`;
CREATE TABLE `address_country` (
  `iso_3166_1_a2` varchar(2) NOT NULL,
  `iso_3166_1_a3` varchar(3) NOT NULL,
  `iso_3166_1_numeric` varchar(3) NOT NULL,
  `printable_name` varchar(128) NOT NULL,
  `name` varchar(128) NOT NULL,
  `display_order` smallint(5) unsigned NOT NULL,
  `is_shipping_country` tinyint(1) NOT NULL,
  PRIMARY KEY (`iso_3166_1_a2`),
  KEY `address_country_010c8bce` (`display_order`),
  KEY `address_country_0b3676f8` (`is_shipping_country`)
);

LOCK TABLES `address_country` WRITE;
INSERT INTO `address_country` VALUES ('AD','AND','020','Andorra','Principality of Andorra',0,1),('AE','ARE','784','United Arab Emirates','',0,1),('AF','AFG','004','Afghanistan','Islamic Republic of Afghanistan',0,1),('AG','ATG','028','Antigua and Barbuda','',0,1),('AI','AIA','660','Anguilla','',0,1),('AL','ALB','008','Albania','Republic of Albania',0,1),('AM','ARM','051','Armenia','Republic of Armenia',0,1),('AO','AGO','024','Angola','Republic of Angola',0,1),('AQ','ATA','010','Antarctica','',0,1),('AR','ARG','032','Argentina','Argentine Republic',0,1),('AS','ASM','016','American Samoa','',0,1),('AT','AUT','040','Austria','Republic of Austria',0,1),('AU','AUS','036','Australia','',0,1),('AW','ABW','533','Aruba','',0,1),('AX','ALA','248','Åland Islands','',0,1),('AZ','AZE','031','Azerbaijan','Republic of Azerbaijan',0,1),('BA','BIH','070','Bosnia and Herzegovina','Republic of Bosnia and Herzegovina',0,1),('BB','BRB','052','Barbados','',0,1),('BD','BGD','050','Bangladesh','People\'s Republic of Bangladesh',0,1),('BE','BEL','056','Belgium','Kingdom of Belgium',0,1),('BF','BFA','854','Burkina Faso','',0,1),('BG','BGR','100','Bulgaria','Republic of Bulgaria',0,1),('BH','BHR','048','Bahrain','Kingdom of Bahrain',0,1),('BI','BDI','108','Burundi','Republic of Burundi',0,1),('BJ','BEN','204','Benin','Republic of Benin',0,1),('BL','BLM','652','Saint Barthélemy','',0,1),('BM','BMU','060','Bermuda','',0,1),('BN','BRN','096','Brunei Darussalam','',0,1),('BO','BOL','068','Bolivia, Plurinational State of','Plurinational State of Bolivia',0,1),('BQ','BES','535','Bonaire, Sint Eustatius and Saba','Bonaire, Sint Eustatius and Saba',0,1),('BR','BRA','076','Brazil','Federative Republic of Brazil',0,1),('BS','BHS','044','Bahamas','Commonwealth of the Bahamas',0,1),('BT','BTN','064','Bhutan','Kingdom of Bhutan',0,1),('BV','BVT','074','Bouvet Island','',0,1),('BW','BWA','072','Botswana','Republic of Botswana',0,1),('BY','BLR','112','Belarus','Republic of Belarus',0,1),('BZ','BLZ','084','Belize','',0,1),('CA','CAN','124','Canada','',0,1),('CC','CCK','166','Cocos (Keeling) Islands','',0,1),('CD','COD','180','Congo, The Democratic Republic of the','',0,1),('CF','CAF','140','Central African Republic','',0,1),('CG','COG','178','Congo','Republic of the Congo',0,1),('CH','CHE','756','Switzerland','Swiss Confederation',0,1),('CI','CIV','384','Côte d\'Ivoire','Republic of Côte d\'Ivoire',0,1),('CK','COK','184','Cook Islands','',0,1),('CL','CHL','152','Chile','Republic of Chile',0,1),('CM','CMR','120','Cameroon','Republic of Cameroon',0,1),('CN','CHN','156','China','People\'s Republic of China',0,1),('CO','COL','170','Colombia','Republic of Colombia',0,1),('CR','CRI','188','Costa Rica','Republic of Costa Rica',0,1),('CU','CUB','192','Cuba','Republic of Cuba',0,1),('CV','CPV','132','Cape Verde','Republic of Cape Verde',0,1),('CW','CUW','531','Curaçao','Curaçao',0,1),('CX','CXR','162','Christmas Island','',0,1),('CY','CYP','196','Cyprus','Republic of Cyprus',0,1),('CZ','CZE','203','Czech Republic','',0,1),('DE','DEU','276','Germany','Federal Republic of Germany',0,1),('DJ','DJI','262','Djibouti','Republic of Djibouti',0,1),('DK','DNK','208','Denmark','Kingdom of Denmark',0,1),('DM','DMA','212','Dominica','Commonwealth of Dominica',0,1),('DO','DOM','214','Dominican Republic','',0,1),('DZ','DZA','012','Algeria','People\'s Democratic Republic of Algeria',0,1),('EC','ECU','218','Ecuador','Republic of Ecuador',0,1),('EE','EST','233','Estonia','Republic of Estonia',0,1),('EG','EGY','818','Egypt','Arab Republic of Egypt',0,1),('EH','ESH','732','Western Sahara','',0,1),('ER','ERI','232','Eritrea','the State of Eritrea',0,1),('ES','ESP','724','Spain','Kingdom of Spain',0,1),('ET','ETH','231','Ethiopia','Federal Democratic Republic of Ethiopia',0,1),('FI','FIN','246','Finland','Republic of Finland',0,1),('FJ','FJI','242','Fiji','Republic of Fiji',0,1),('FK','FLK','238','Falkland Islands (Malvinas)','',0,1),('FM','FSM','583','Micronesia, Federated States of','Federated States of Micronesia',0,1),('FO','FRO','234','Faroe Islands','',0,1),('FR','FRA','250','France','French Republic',0,1),('GA','GAB','266','Gabon','Gabonese Republic',0,1),('GB','GBR','826','United Kingdom','United Kingdom of Great Britain and Northern Ireland',0,1),('GD','GRD','308','Grenada','',0,1),('GE','GEO','268','Georgia','',0,1),('GF','GUF','254','French Guiana','',0,1),('GG','GGY','831','Guernsey','',0,1),('GH','GHA','288','Ghana','Republic of Ghana',0,1),('GI','GIB','292','Gibraltar','',0,1),('GL','GRL','304','Greenland','',0,1),('GM','GMB','270','Gambia','Republic of the Gambia',0,1),('GN','GIN','324','Guinea','Republic of Guinea',0,1),('GP','GLP','312','Guadeloupe','',0,1),('GQ','GNQ','226','Equatorial Guinea','Republic of Equatorial Guinea',0,1),('GR','GRC','300','Greece','Hellenic Republic',0,1),('GS','SGS','239','South Georgia and the South Sandwich Islands','',0,1),('GT','GTM','320','Guatemala','Republic of Guatemala',0,1),('GU','GUM','316','Guam','',0,1),('GW','GNB','624','Guinea-Bissau','Republic of Guinea-Bissau',0,1),('GY','GUY','328','Guyana','Republic of Guyana',0,1),('HK','HKG','344','Hong Kong','Hong Kong Special Administrative Region of China',0,1),('HM','HMD','334','Heard Island and McDonald Islands','',0,1),('HN','HND','340','Honduras','Republic of Honduras',0,1),('HR','HRV','191','Croatia','Republic of Croatia',0,1),('HT','HTI','332','Haiti','Republic of Haiti',0,1),('HU','HUN','348','Hungary','Hungary',0,1),('ID','IDN','360','Indonesia','Republic of Indonesia',0,1),('IE','IRL','372','Ireland','',0,1),('IL','ISR','376','Israel','State of Israel',0,1),('IM','IMN','833','Isle of Man','',0,1),('IN','IND','356','India','Republic of India',0,1),('IO','IOT','086','British Indian Ocean Territory','',0,1),('IQ','IRQ','368','Iraq','Republic of Iraq',0,1),('IR','IRN','364','Iran, Islamic Republic of','Islamic Republic of Iran',0,1),('IS','ISL','352','Iceland','Republic of Iceland',0,1),('IT','ITA','380','Italy','Italian Republic',0,1),('JE','JEY','832','Jersey','',0,1),('JM','JAM','388','Jamaica','',0,1),('JO','JOR','400','Jordan','Hashemite Kingdom of Jordan',0,1),('JP','JPN','392','Japan','',0,1),('KE','KEN','404','Kenya','Republic of Kenya',0,1),('KG','KGZ','417','Kyrgyzstan','Kyrgyz Republic',0,1),('KH','KHM','116','Cambodia','Kingdom of Cambodia',0,1),('KI','KIR','296','Kiribati','Republic of Kiribati',0,1),('KM','COM','174','Comoros','Union of the Comoros',0,1),('KN','KNA','659','Saint Kitts and Nevis','',0,1),('KP','PRK','408','Korea, Democratic People\'s Republic of','Democratic People\'s Republic of Korea',0,1),('KR','KOR','410','Korea, Republic of','',0,1),('KW','KWT','414','Kuwait','State of Kuwait',0,1),('KY','CYM','136','Cayman Islands','',0,1),('KZ','KAZ','398','Kazakhstan','Republic of Kazakhstan',0,1),('LA','LAO','418','Lao People\'s Democratic Republic','',0,1),('LB','LBN','422','Lebanon','Lebanese Republic',0,1),('LC','LCA','662','Saint Lucia','',0,1),('LI','LIE','438','Liechtenstein','Principality of Liechtenstein',0,1),('LK','LKA','144','Sri Lanka','Democratic Socialist Republic of Sri Lanka',0,1),('LR','LBR','430','Liberia','Republic of Liberia',0,1),('LS','LSO','426','Lesotho','Kingdom of Lesotho',0,1),('LT','LTU','440','Lithuania','Republic of Lithuania',0,1),('LU','LUX','442','Luxembourg','Grand Duchy of Luxembourg',0,1),('LV','LVA','428','Latvia','Republic of Latvia',0,1),('LY','LBY','434','Libya','Libya',0,1),('MA','MAR','504','Morocco','Kingdom of Morocco',0,1),('MC','MCO','492','Monaco','Principality of Monaco',0,1),('MD','MDA','498','Moldova, Republic of','Republic of Moldova',0,1),('ME','MNE','499','Montenegro','Montenegro',0,1),('MF','MAF','663','Saint Martin (French part)','',0,1),('MG','MDG','450','Madagascar','Republic of Madagascar',0,1),('MH','MHL','584','Marshall Islands','Republic of the Marshall Islands',0,1),('MK','MKD','807','Macedonia, Republic of','The Former Yugoslav Republic of Macedonia',0,1),('ML','MLI','466','Mali','Republic of Mali',0,1),('MM','MMR','104','Myanmar','Republic of Myanmar',0,1),('MN','MNG','496','Mongolia','',0,1),('MO','MAC','446','Macao','Macao Special Administrative Region of China',0,1),('MP','MNP','580','Northern Mariana Islands','Commonwealth of the Northern Mariana Islands',0,1),('MQ','MTQ','474','Martinique','',0,1),('MR','MRT','478','Mauritania','Islamic Republic of Mauritania',0,1),('MS','MSR','500','Montserrat','',0,1),('MT','MLT','470','Malta','Republic of Malta',0,1),('MU','MUS','480','Mauritius','Republic of Mauritius',0,1),('MV','MDV','462','Maldives','Republic of Maldives',0,1),('MW','MWI','454','Malawi','Republic of Malawi',0,1),('MX','MEX','484','Mexico','United Mexican States',0,1),('MY','MYS','458','Malaysia','',0,1),('MZ','MOZ','508','Mozambique','Republic of Mozambique',0,1),('NA','NAM','516','Namibia','Republic of Namibia',0,1),('NC','NCL','540','New Caledonia','',0,1),('NE','NER','562','Niger','Republic of the Niger',0,1),('NF','NFK','574','Norfolk Island','',0,1),('NG','NGA','566','Nigeria','Federal Republic of Nigeria',0,1),('NI','NIC','558','Nicaragua','Republic of Nicaragua',0,1),('NL','NLD','528','Netherlands','Kingdom of the Netherlands',0,1),('NO','NOR','578','Norway','Kingdom of Norway',0,1),('NP','NPL','524','Nepal','Federal Democratic Republic of Nepal',0,1),('NR','NRU','520','Nauru','Republic of Nauru',0,1),('NU','NIU','570','Niue','Niue',0,1),('NZ','NZL','554','New Zealand','',0,1),('OM','OMN','512','Oman','Sultanate of Oman',0,1),('PA','PAN','591','Panama','Republic of Panama',0,1),('PE','PER','604','Peru','Republic of Peru',0,1),('PF','PYF','258','French Polynesia','',0,1),('PG','PNG','598','Papua New Guinea','Independent State of Papua New Guinea',0,1),('PH','PHL','608','Philippines','Republic of the Philippines',0,1),('PK','PAK','586','Pakistan','Islamic Republic of Pakistan',0,1),('PL','POL','616','Poland','Republic of Poland',0,1),('PM','SPM','666','Saint Pierre and Miquelon','',0,1),('PN','PCN','612','Pitcairn','',0,1),('PR','PRI','630','Puerto Rico','',0,1),('PS','PSE','275','Palestine, State of','the State of Palestine',0,1),('PT','PRT','620','Portugal','Portuguese Republic',0,1),('PW','PLW','585','Palau','Republic of Palau',0,1),('PY','PRY','600','Paraguay','Republic of Paraguay',0,1),('QA','QAT','634','Qatar','State of Qatar',0,1),('RE','REU','638','Réunion','',0,1),('RO','ROU','642','Romania','',0,1),('RS','SRB','688','Serbia','Republic of Serbia',0,1),('RU','RUS','643','Russian Federation','',0,1),('RW','RWA','646','Rwanda','Rwandese Republic',0,1),('SA','SAU','682','Saudi Arabia','Kingdom of Saudi Arabia',0,1),('SB','SLB','090','Solomon Islands','',0,1),('SC','SYC','690','Seychelles','Republic of Seychelles',0,1),('SD','SDN','729','Sudan','Republic of the Sudan',0,1),('SE','SWE','752','Sweden','Kingdom of Sweden',0,1),('SG','SGP','702','Singapore','Republic of Singapore',0,1),('SH','SHN','654','Saint Helena, Ascension and Tristan da Cunha','',0,1),('SI','SVN','705','Slovenia','Republic of Slovenia',0,1),('SJ','SJM','744','Svalbard and Jan Mayen','',0,1),('SK','SVK','703','Slovakia','Slovak Republic',0,1),('SL','SLE','694','Sierra Leone','Republic of Sierra Leone',0,1),('SM','SMR','674','San Marino','Republic of San Marino',0,1),('SN','SEN','686','Senegal','Republic of Senegal',0,1),('SO','SOM','706','Somalia','Federal Republic of Somalia',0,1),('SR','SUR','740','Suriname','Republic of Suriname',0,1),('SS','SSD','728','South Sudan','Republic of South Sudan',0,1),('ST','STP','678','Sao Tome and Principe','Democratic Republic of Sao Tome and Principe',0,1),('SV','SLV','222','El Salvador','Republic of El Salvador',0,1),('SX','SXM','534','Sint Maarten (Dutch part)','Sint Maarten (Dutch part)',0,1),('SY','SYR','760','Syrian Arab Republic','',0,1),('SZ','SWZ','748','Swaziland','Kingdom of Swaziland',0,1),('TC','TCA','796','Turks and Caicos Islands','',0,1),('TD','TCD','148','Chad','Republic of Chad',0,1),('TF','ATF','260','French Southern Territories','',0,1),('TG','TGO','768','Togo','Togolese Republic',0,1),('TH','THA','764','Thailand','Kingdom of Thailand',0,1),('TJ','TJK','762','Tajikistan','Republic of Tajikistan',0,1),('TK','TKL','772','Tokelau','',0,1),('TL','TLS','626','Timor-Leste','Democratic Republic of Timor-Leste',0,1),('TM','TKM','795','Turkmenistan','',0,1),('TN','TUN','788','Tunisia','Republic of Tunisia',0,1),('TO','TON','776','Tonga','Kingdom of Tonga',0,1),('TR','TUR','792','Turkey','Republic of Turkey',0,1),('TT','TTO','780','Trinidad and Tobago','Republic of Trinidad and Tobago',0,1),('TV','TUV','798','Tuvalu','',0,1),('TW','TWN','158','Taiwan, Province of China','Taiwan, Province of China',0,1),('TZ','TZA','834','Tanzania, United Republic of','United Republic of Tanzania',0,1),('UA','UKR','804','Ukraine','',0,1),('UG','UGA','800','Uganda','Republic of Uganda',0,1),('UM','UMI','581','United States Minor Outlying Islands','',0,1),('US','USA','840','United States','United States of America',0,1),('UY','URY','858','Uruguay','Eastern Republic of Uruguay',0,1),('UZ','UZB','860','Uzbekistan','Republic of Uzbekistan',0,1),('VA','VAT','336','Holy See (Vatican City State)','',0,1),('VC','VCT','670','Saint Vincent and the Grenadines','',0,1),('VE','VEN','862','Venezuela, Bolivarian Republic of','Bolivarian Republic of Venezuela',0,1),('VG','VGB','092','Virgin Islands, British','British Virgin Islands',0,1),('VI','VIR','850','Virgin Islands, U.S.','Virgin Islands of the United States',0,1),('VN','VNM','704','Viet Nam','Socialist Republic of Viet Nam',0,1),('VU','VUT','548','Vanuatu','Republic of Vanuatu',0,1),('WF','WLF','876','Wallis and Futuna','',0,1),('WS','WSM','882','Samoa','Independent State of Samoa',0,1),('YE','YEM','887','Yemen','Republic of Yemen',0,1),('YT','MYT','175','Mayotte','',0,1),('ZA','ZAF','710','South Africa','Republic of South Africa',0,1),('ZM','ZMB','894','Zambia','Republic of Zambia',0,1),('ZW','ZWE','716','Zimbabwe','Republic of Zimbabwe',0,1);
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
INSERT INTO `django_content_type` VALUES (8,'address','country'),(9,'address','useraddress'),(10,'admin','logentry'),(28,'analytics','productrecord'),(25,'analytics','userproductview'),(26,'analytics','userrecord'),(27,'analytics','usersearch'),(4,'auth','group'),(3,'auth','permission'),(41,'basket','basket'),(39,'basket','basketattribute'),(40,'basket','basketattributetype'),(42,'basket','line'),(43,'basket','lineattribute'),(11,'catalogue','attributeoption'),(19,'catalogue','attributeoptiongroup'),(16,'catalogue','catalog'),(15,'catalogue','category'),(24,'catalogue','historicalproduct'),(23,'catalogue','historicalproductattributevalue'),(13,'catalogue','option'),(12,'catalogue','product'),(18,'catalogue','productattribute'),(21,'catalogue','productattributevalue'),(22,'catalogue','productcategory'),(14,'catalogue','productclass'),(20,'catalogue','productimage'),(17,'catalogue','productrecommendation'),(2,'contenttypes','contenttype'),(73,'core','businessclient'),(7,'core','client'),(5,'core','siteconfiguration'),(6,'core','user'),(67,'courses','course'),(74,'courses','historicalcourse'),(37,'customer','communicationeventtype'),(36,'customer','email'),(38,'customer','notification'),(35,'customer','productalert'),(71,'flatpages','flatpage'),(75,'invoice','historicalinvoice'),(76,'invoice','invoice'),(99,'offer','absolutediscountbenefit'),(60,'offer','benefit'),(62,'offer','condition'),(63,'offer','conditionaloffer'),(96,'offer','countcondition'),(104,'offer','coveragecondition'),(105,'offer','fixedpricebenefit'),(101,'offer','multibuydiscountbenefit'),(103,'offer','percentagediscountbenefit'),(61,'offer','range'),(59,'offer','rangeproduct'),(64,'offer','rangeproductfileupload'),(102,'offer','shippingabsolutediscountbenefit'),(100,'offer','shippingbenefit'),(95,'offer','shippingfixedpricebenefit'),(98,'offer','shippingpercentagediscountbenefit'),(97,'offer','valuecondition'),(46,'order','billingaddress'),(50,'order','communicationevent'),(107,'order','historicalline'),(106,'order','historicalorder'),(48,'order','line'),(57,'order','lineattribute'),(44,'order','lineprice'),(52,'order','order'),(58,'order','orderdiscount'),(51,'order','ordernote'),(49,'order','paymentevent'),(53,'order','paymenteventquantity'),(56,'order','paymenteventtype'),(45,'order','shippingaddress'),(47,'order','shippingevent'),(55,'order','shippingeventquantity'),(54,'order','shippingeventtype'),(30,'partner','historicalstockrecord'),(31,'partner','partner'),(32,'partner','partneraddress'),(34,'partner','stockalert'),(33,'partner','stockrecord'),(94,'payment','bankcard'),(88,'payment','paymentprocessorresponse'),(91,'payment','paypalprocessorconfiguration'),(90,'payment','paypalwebprofile'),(89,'payment','source'),(93,'payment','sourcetype'),(92,'payment','transaction'),(116,'promotions','automaticproductlist'),(114,'promotions','handpickedproductlist'),(111,'promotions','image'),(109,'promotions','keywordpromotion'),(112,'promotions','multiimage'),(115,'promotions','orderedproduct'),(117,'promotions','orderedproductlist'),(108,'promotions','pagepromotion'),(110,'promotions','rawhtml'),(113,'promotions','singleproduct'),(118,'promotions','tabbedblock'),(77,'referrals','referral'),(79,'refund','historicalrefund'),(81,'refund','historicalrefundline'),(80,'refund','refund'),(82,'refund','refundline'),(86,'reviews','productreview'),(87,'reviews','vote'),(72,'sessions','session'),(83,'shipping','orderanditemcharges'),(85,'shipping','weightband'),(84,'shipping','weightbased'),(29,'sites','site'),(125,'social_auth','association'),(126,'social_auth','code'),(124,'social_auth','nonce'),(123,'social_auth','usersocialauth'),(78,'theming','sitetheme'),(1,'thumbnail','kvstore'),(119,'voucher','couponvouchers'),(120,'voucher','orderlinevouchers'),(66,'voucher','voucher'),(65,'voucher','voucherapplication'),(70,'waffle','flag'),(68,'waffle','sample'),(69,'waffle','switch'),(122,'wishlists','line'),(121,'wishlists','wishlist');
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

LOCK TABLES `auth_permission` WRITE;
INSERT INTO `auth_permission` VALUES (1,'Can add kv store',1,'add_kvstore'),(2,'Can change kv store',1,'change_kvstore'),(3,'Can delete kv store',1,'delete_kvstore'),(4,'Can add content type',2,'add_contenttype'),(5,'Can change content type',2,'change_contenttype'),(6,'Can delete content type',2,'delete_contenttype'),(7,'Can add permission',3,'add_permission'),(8,'Can change permission',3,'change_permission'),(9,'Can delete permission',3,'delete_permission'),(10,'Can add group',4,'add_group'),(11,'Can change group',4,'change_group'),(12,'Can delete group',4,'delete_group'),(13,'Can add site configuration',5,'add_siteconfiguration'),(14,'Can change site configuration',5,'change_siteconfiguration'),(15,'Can delete site configuration',5,'delete_siteconfiguration'),(16,'Can add user',6,'add_user'),(17,'Can change user',6,'change_user'),(18,'Can delete user',6,'delete_user'),(19,'Can add user',7,'add_client'),(20,'Can change user',7,'change_client'),(21,'Can delete user',7,'delete_client'),(22,'Can add Country',8,'add_country'),(23,'Can change Country',8,'change_country'),(24,'Can delete Country',8,'delete_country'),(25,'Can add User address',9,'add_useraddress'),(26,'Can change User address',9,'change_useraddress'),(27,'Can delete User address',9,'delete_useraddress'),(28,'Can add log entry',10,'add_logentry'),(29,'Can change log entry',10,'change_logentry'),(30,'Can delete log entry',10,'delete_logentry'),(31,'Can add Attribute option',11,'add_attributeoption'),(32,'Can change Attribute option',11,'change_attributeoption'),(33,'Can delete Attribute option',11,'delete_attributeoption'),(34,'Can add Product',12,'add_product'),(35,'Can change Product',12,'change_product'),(36,'Can delete Product',12,'delete_product'),(37,'Can add Option',13,'add_option'),(38,'Can change Option',13,'change_option'),(39,'Can delete Option',13,'delete_option'),(40,'Can add Product class',14,'add_productclass'),(41,'Can change Product class',14,'change_productclass'),(42,'Can delete Product class',14,'delete_productclass'),(43,'Can add Category',15,'add_category'),(44,'Can change Category',15,'change_category'),(45,'Can delete Category',15,'delete_category'),(46,'Can add catalog',16,'add_catalog'),(47,'Can change catalog',16,'change_catalog'),(48,'Can delete catalog',16,'delete_catalog'),(49,'Can add Product recommendation',17,'add_productrecommendation'),(50,'Can change Product recommendation',17,'change_productrecommendation'),(51,'Can delete Product recommendation',17,'delete_productrecommendation'),(52,'Can add Product attribute',18,'add_productattribute'),(53,'Can change Product attribute',18,'change_productattribute'),(54,'Can delete Product attribute',18,'delete_productattribute'),(55,'Can add Attribute option group',19,'add_attributeoptiongroup'),(56,'Can change Attribute option group',19,'change_attributeoptiongroup'),(57,'Can delete Attribute option group',19,'delete_attributeoptiongroup'),(58,'Can add Product image',20,'add_productimage'),(59,'Can change Product image',20,'change_productimage'),(60,'Can delete Product image',20,'delete_productimage'),(61,'Can add Product attribute value',21,'add_productattributevalue'),(62,'Can change Product attribute value',21,'change_productattributevalue'),(63,'Can delete Product attribute value',21,'delete_productattributevalue'),(64,'Can add Product category',22,'add_productcategory'),(65,'Can change Product category',22,'change_productcategory'),(66,'Can delete Product category',22,'delete_productcategory'),(67,'Can add historical Product attribute value',23,'add_historicalproductattributevalue'),(68,'Can change historical Product attribute value',23,'change_historicalproductattributevalue'),(69,'Can delete historical Product attribute value',23,'delete_historicalproductattributevalue'),(70,'Can add historical Product',24,'add_historicalproduct'),(71,'Can change historical Product',24,'change_historicalproduct'),(72,'Can delete historical Product',24,'delete_historicalproduct'),(73,'Can add User product view',25,'add_userproductview'),(74,'Can change User product view',25,'change_userproductview'),(75,'Can delete User product view',25,'delete_userproductview'),(76,'Can add User record',26,'add_userrecord'),(77,'Can change User record',26,'change_userrecord'),(78,'Can delete User record',26,'delete_userrecord'),(79,'Can add User search query',27,'add_usersearch'),(80,'Can change User search query',27,'change_usersearch'),(81,'Can delete User search query',27,'delete_usersearch'),(82,'Can add Product record',28,'add_productrecord'),(83,'Can change Product record',28,'change_productrecord'),(84,'Can delete Product record',28,'delete_productrecord'),(85,'Can add site',29,'add_site'),(86,'Can change site',29,'change_site'),(87,'Can delete site',29,'delete_site'),(88,'Can add historical Stock record',30,'add_historicalstockrecord'),(89,'Can change historical Stock record',30,'change_historicalstockrecord'),(90,'Can delete historical Stock record',30,'delete_historicalstockrecord'),(91,'Can add Partner',31,'add_partner'),(92,'Can change Partner',31,'change_partner'),(93,'Can delete Partner',31,'delete_partner'),(94,'Can add Partner address',32,'add_partneraddress'),(95,'Can change Partner address',32,'change_partneraddress'),(96,'Can delete Partner address',32,'delete_partneraddress'),(97,'Can add Stock record',33,'add_stockrecord'),(98,'Can change Stock record',33,'change_stockrecord'),(99,'Can delete Stock record',33,'delete_stockrecord'),(100,'Can add Stock alert',34,'add_stockalert'),(101,'Can change Stock alert',34,'change_stockalert'),(102,'Can delete Stock alert',34,'delete_stockalert'),(103,'Can add Product alert',35,'add_productalert'),(104,'Can change Product alert',35,'change_productalert'),(105,'Can delete Product alert',35,'delete_productalert'),(106,'Can add Email',36,'add_email'),(107,'Can change Email',36,'change_email'),(108,'Can delete Email',36,'delete_email'),(109,'Can add Communication event type',37,'add_communicationeventtype'),(110,'Can change Communication event type',37,'change_communicationeventtype'),(111,'Can delete Communication event type',37,'delete_communicationeventtype'),(112,'Can add Notification',38,'add_notification'),(113,'Can change Notification',38,'change_notification'),(114,'Can delete Notification',38,'delete_notification'),(115,'Can add basket attribute',39,'add_basketattribute'),(116,'Can change basket attribute',39,'change_basketattribute'),(117,'Can delete basket attribute',39,'delete_basketattribute'),(118,'Can add basket attribute type',40,'add_basketattributetype'),(119,'Can change basket attribute type',40,'change_basketattributetype'),(120,'Can delete basket attribute type',40,'delete_basketattributetype'),(121,'Can add Basket',41,'add_basket'),(122,'Can change Basket',41,'change_basket'),(123,'Can delete Basket',41,'delete_basket'),(124,'Can add Basket line',42,'add_line'),(125,'Can change Basket line',42,'change_line'),(126,'Can delete Basket line',42,'delete_line'),(127,'Can add Line attribute',43,'add_lineattribute'),(128,'Can change Line attribute',43,'change_lineattribute'),(129,'Can delete Line attribute',43,'delete_lineattribute'),(130,'Can add Line Price',44,'add_lineprice'),(131,'Can change Line Price',44,'change_lineprice'),(132,'Can delete Line Price',44,'delete_lineprice'),(133,'Can add Shipping address',45,'add_shippingaddress'),(134,'Can change Shipping address',45,'change_shippingaddress'),(135,'Can delete Shipping address',45,'delete_shippingaddress'),(136,'Can add Billing address',46,'add_billingaddress'),(137,'Can change Billing address',46,'change_billingaddress'),(138,'Can delete Billing address',46,'delete_billingaddress'),(139,'Can add Shipping Event',47,'add_shippingevent'),(140,'Can change Shipping Event',47,'change_shippingevent'),(141,'Can delete Shipping Event',47,'delete_shippingevent'),(142,'Can add Order Line',48,'add_line'),(143,'Can change Order Line',48,'change_line'),(144,'Can delete Order Line',48,'delete_line'),(145,'Can add Payment Event',49,'add_paymentevent'),(146,'Can change Payment Event',49,'change_paymentevent'),(147,'Can delete Payment Event',49,'delete_paymentevent'),(148,'Can add Communication Event',50,'add_communicationevent'),(149,'Can change Communication Event',50,'change_communicationevent'),(150,'Can delete Communication Event',50,'delete_communicationevent'),(151,'Can add Order Note',51,'add_ordernote'),(152,'Can change Order Note',51,'change_ordernote'),(153,'Can delete Order Note',51,'delete_ordernote'),(154,'Can add Order',52,'add_order'),(155,'Can change Order',52,'change_order'),(156,'Can delete Order',52,'delete_order'),(157,'Can add Payment Event Quantity',53,'add_paymenteventquantity'),(158,'Can change Payment Event Quantity',53,'change_paymenteventquantity'),(159,'Can delete Payment Event Quantity',53,'delete_paymenteventquantity'),(160,'Can add Shipping Event Type',54,'add_shippingeventtype'),(161,'Can change Shipping Event Type',54,'change_shippingeventtype'),(162,'Can delete Shipping Event Type',54,'delete_shippingeventtype'),(163,'Can add Shipping Event Quantity',55,'add_shippingeventquantity'),(164,'Can change Shipping Event Quantity',55,'change_shippingeventquantity'),(165,'Can delete Shipping Event Quantity',55,'delete_shippingeventquantity'),(166,'Can add Payment Event Type',56,'add_paymenteventtype'),(167,'Can change Payment Event Type',56,'change_paymenteventtype'),(168,'Can delete Payment Event Type',56,'delete_paymenteventtype'),(169,'Can add Line Attribute',57,'add_lineattribute'),(170,'Can change Line Attribute',57,'change_lineattribute'),(171,'Can delete Line Attribute',57,'delete_lineattribute'),(172,'Can add Order Discount',58,'add_orderdiscount'),(173,'Can change Order Discount',58,'change_orderdiscount'),(174,'Can delete Order Discount',58,'delete_orderdiscount'),(175,'Can add range product',59,'add_rangeproduct'),(176,'Can change range product',59,'change_rangeproduct'),(177,'Can delete range product',59,'delete_rangeproduct'),(178,'Can add Benefit',60,'add_benefit'),(179,'Can change Benefit',60,'change_benefit'),(180,'Can delete Benefit',60,'delete_benefit'),(181,'Can add Multibuy discount benefit',60,'add_multibuydiscountbenefit'),(182,'Can change Multibuy discount benefit',60,'change_multibuydiscountbenefit'),(183,'Can delete Multibuy discount benefit',60,'delete_multibuydiscountbenefit'),(184,'Can add Range',61,'add_range'),(185,'Can change Range',61,'change_range'),(186,'Can delete Range',61,'delete_range'),(187,'Can add Condition',62,'add_condition'),(188,'Can change Condition',62,'change_condition'),(189,'Can delete Condition',62,'delete_condition'),(190,'Can add shipping benefit',60,'add_shippingbenefit'),(191,'Can change shipping benefit',60,'change_shippingbenefit'),(192,'Can delete shipping benefit',60,'delete_shippingbenefit'),(193,'Can add Shipping percentage discount benefit',60,'add_shippingpercentagediscountbenefit'),(194,'Can change Shipping percentage discount benefit',60,'change_shippingpercentagediscountbenefit'),(195,'Can delete Shipping percentage discount benefit',60,'delete_shippingpercentagediscountbenefit'),(196,'Can add Conditional offer',63,'add_conditionaloffer'),(197,'Can change Conditional offer',63,'change_conditionaloffer'),(198,'Can delete Conditional offer',63,'delete_conditionaloffer'),(199,'Can add Shipping absolute discount benefit',60,'add_shippingabsolutediscountbenefit'),(200,'Can change Shipping absolute discount benefit',60,'change_shippingabsolutediscountbenefit'),(201,'Can delete Shipping absolute discount benefit',60,'delete_shippingabsolutediscountbenefit'),(202,'Can add Percentage discount benefit',60,'add_percentagediscountbenefit'),(203,'Can change Percentage discount benefit',60,'change_percentagediscountbenefit'),(204,'Can delete Percentage discount benefit',60,'delete_percentagediscountbenefit'),(205,'Can add Absolute discount benefit',60,'add_absolutediscountbenefit'),(206,'Can change Absolute discount benefit',60,'change_absolutediscountbenefit'),(207,'Can delete Absolute discount benefit',60,'delete_absolutediscountbenefit'),(208,'Can add Coverage Condition',62,'add_coveragecondition'),(209,'Can change Coverage Condition',62,'change_coveragecondition'),(210,'Can delete Coverage Condition',62,'delete_coveragecondition'),(211,'Can add Range Product Uploaded File',64,'add_rangeproductfileupload'),(212,'Can change Range Product Uploaded File',64,'change_rangeproductfileupload'),(213,'Can delete Range Product Uploaded File',64,'delete_rangeproductfileupload'),(214,'Can add Fixed price benefit',60,'add_fixedpricebenefit'),(215,'Can change Fixed price benefit',60,'change_fixedpricebenefit'),(216,'Can delete Fixed price benefit',60,'delete_fixedpricebenefit'),(217,'Can add Fixed price shipping benefit',60,'add_shippingfixedpricebenefit'),(218,'Can change Fixed price shipping benefit',60,'change_shippingfixedpricebenefit'),(219,'Can delete Fixed price shipping benefit',60,'delete_shippingfixedpricebenefit'),(220,'Can add Value condition',62,'add_valuecondition'),(221,'Can change Value condition',62,'change_valuecondition'),(222,'Can delete Value condition',62,'delete_valuecondition'),(223,'Can add Count condition',62,'add_countcondition'),(224,'Can change Count condition',62,'change_countcondition'),(225,'Can delete Count condition',62,'delete_countcondition'),(226,'Can add Voucher Application',65,'add_voucherapplication'),(227,'Can change Voucher Application',65,'change_voucherapplication'),(228,'Can delete Voucher Application',65,'delete_voucherapplication'),(229,'Can add Voucher',66,'add_voucher'),(230,'Can change Voucher',66,'change_voucher'),(231,'Can delete Voucher',66,'delete_voucher'),(232,'Can add course',67,'add_course'),(233,'Can change course',67,'change_course'),(234,'Can delete course',67,'delete_course'),(235,'Can add sample',68,'add_sample'),(236,'Can change sample',68,'change_sample'),(237,'Can delete sample',68,'delete_sample'),(238,'Can add switch',69,'add_switch'),(239,'Can change switch',69,'change_switch'),(240,'Can delete switch',69,'delete_switch'),(241,'Can add flag',70,'add_flag'),(242,'Can change flag',70,'change_flag'),(243,'Can delete flag',70,'delete_flag'),(244,'Can add flat page',71,'add_flatpage'),(245,'Can change flat page',71,'change_flatpage'),(246,'Can delete flat page',71,'delete_flatpage'),(247,'Can add session',72,'add_session'),(248,'Can change session',72,'change_session'),(249,'Can delete session',72,'delete_session'),(250,'Can add business client',73,'add_businessclient'),(251,'Can change business client',73,'change_businessclient'),(252,'Can delete business client',73,'delete_businessclient'),(253,'Can add historical course',74,'add_historicalcourse'),(254,'Can change historical course',74,'change_historicalcourse'),(255,'Can delete historical course',74,'delete_historicalcourse'),(256,'Can add historical invoice',75,'add_historicalinvoice'),(257,'Can change historical invoice',75,'change_historicalinvoice'),(258,'Can delete historical invoice',75,'delete_historicalinvoice'),(259,'Can add invoice',76,'add_invoice'),(260,'Can change invoice',76,'change_invoice'),(261,'Can delete invoice',76,'delete_invoice'),(262,'Can add referral',77,'add_referral'),(263,'Can change referral',77,'change_referral'),(264,'Can delete referral',77,'delete_referral'),(265,'Can add site theme',78,'add_sitetheme'),(266,'Can change site theme',78,'change_sitetheme'),(267,'Can delete site theme',78,'delete_sitetheme'),(268,'Can add historical refund',79,'add_historicalrefund'),(269,'Can change historical refund',79,'change_historicalrefund'),(270,'Can delete historical refund',79,'delete_historicalrefund'),(271,'Can add refund',80,'add_refund'),(272,'Can change refund',80,'change_refund'),(273,'Can delete refund',80,'delete_refund'),(274,'Can add historical refund line',81,'add_historicalrefundline'),(275,'Can change historical refund line',81,'change_historicalrefundline'),(276,'Can delete historical refund line',81,'delete_historicalrefundline'),(277,'Can add refund line',82,'add_refundline'),(278,'Can change refund line',82,'change_refundline'),(279,'Can delete refund line',82,'delete_refundline'),(280,'Can add Order and Item Charge',83,'add_orderanditemcharges'),(281,'Can change Order and Item Charge',83,'change_orderanditemcharges'),(282,'Can delete Order and Item Charge',83,'delete_orderanditemcharges'),(283,'Can add Weight-based Shipping Method',84,'add_weightbased'),(284,'Can change Weight-based Shipping Method',84,'change_weightbased'),(285,'Can delete Weight-based Shipping Method',84,'delete_weightbased'),(286,'Can add Weight Band',85,'add_weightband'),(287,'Can change Weight Band',85,'change_weightband'),(288,'Can delete Weight Band',85,'delete_weightband'),(289,'Can add Product review',86,'add_productreview'),(290,'Can change Product review',86,'change_productreview'),(291,'Can delete Product review',86,'delete_productreview'),(292,'Can add Vote',87,'add_vote'),(293,'Can change Vote',87,'change_vote'),(294,'Can delete Vote',87,'delete_vote'),(295,'Can add Payment Processor Response',88,'add_paymentprocessorresponse'),(296,'Can change Payment Processor Response',88,'change_paymentprocessorresponse'),(297,'Can delete Payment Processor Response',88,'delete_paymentprocessorresponse'),(298,'Can add Source',89,'add_source'),(299,'Can change Source',89,'change_source'),(300,'Can delete Source',89,'delete_source'),(301,'Can add paypal web profile',90,'add_paypalwebprofile'),(302,'Can change paypal web profile',90,'change_paypalwebprofile'),(303,'Can delete paypal web profile',90,'delete_paypalwebprofile'),(304,'Can add Paypal Processor Configuration',91,'add_paypalprocessorconfiguration'),(305,'Can change Paypal Processor Configuration',91,'change_paypalprocessorconfiguration'),(306,'Can delete Paypal Processor Configuration',91,'delete_paypalprocessorconfiguration'),(307,'Can add Transaction',92,'add_transaction'),(308,'Can change Transaction',92,'change_transaction'),(309,'Can delete Transaction',92,'delete_transaction'),(310,'Can add Source Type',93,'add_sourcetype'),(311,'Can change Source Type',93,'change_sourcetype'),(312,'Can delete Source Type',93,'delete_sourcetype'),(313,'Can add Bankcard',94,'add_bankcard'),(314,'Can change Bankcard',94,'change_bankcard'),(315,'Can delete Bankcard',94,'delete_bankcard'),(316,'Can add historical Order',106,'add_historicalorder'),(317,'Can change historical Order',106,'change_historicalorder'),(318,'Can delete historical Order',106,'delete_historicalorder'),(319,'Can add historical Order Line',107,'add_historicalline'),(320,'Can change historical Order Line',107,'change_historicalline'),(321,'Can delete historical Order Line',107,'delete_historicalline'),(322,'Can add Page Promotion',108,'add_pagepromotion'),(323,'Can change Page Promotion',108,'change_pagepromotion'),(324,'Can delete Page Promotion',108,'delete_pagepromotion'),(325,'Can add Keyword Promotion',109,'add_keywordpromotion'),(326,'Can change Keyword Promotion',109,'change_keywordpromotion'),(327,'Can delete Keyword Promotion',109,'delete_keywordpromotion'),(328,'Can add Raw HTML',110,'add_rawhtml'),(329,'Can change Raw HTML',110,'change_rawhtml'),(330,'Can delete Raw HTML',110,'delete_rawhtml'),(331,'Can add Image',111,'add_image'),(332,'Can change Image',111,'change_image'),(333,'Can delete Image',111,'delete_image'),(334,'Can add Multi Image',112,'add_multiimage'),(335,'Can change Multi Image',112,'change_multiimage'),(336,'Can delete Multi Image',112,'delete_multiimage'),(337,'Can add Single product',113,'add_singleproduct'),(338,'Can change Single product',113,'change_singleproduct'),(339,'Can delete Single product',113,'delete_singleproduct'),(340,'Can add Hand Picked Product List',114,'add_handpickedproductlist'),(341,'Can change Hand Picked Product List',114,'change_handpickedproductlist'),(342,'Can delete Hand Picked Product List',114,'delete_handpickedproductlist'),(343,'Can add Ordered product',115,'add_orderedproduct'),(344,'Can change Ordered product',115,'change_orderedproduct'),(345,'Can delete Ordered product',115,'delete_orderedproduct'),(346,'Can add Automatic product list',116,'add_automaticproductlist'),(347,'Can change Automatic product list',116,'change_automaticproductlist'),(348,'Can delete Automatic product list',116,'delete_automaticproductlist'),(349,'Can add Ordered Product List',117,'add_orderedproductlist'),(350,'Can change Ordered Product List',117,'change_orderedproductlist'),(351,'Can delete Ordered Product List',117,'delete_orderedproductlist'),(352,'Can add Tabbed Block',118,'add_tabbedblock'),(353,'Can change Tabbed Block',118,'change_tabbedblock'),(354,'Can delete Tabbed Block',118,'delete_tabbedblock'),(355,'Can add coupon vouchers',119,'add_couponvouchers'),(356,'Can change coupon vouchers',119,'change_couponvouchers'),(357,'Can delete coupon vouchers',119,'delete_couponvouchers'),(358,'Can add order line vouchers',120,'add_orderlinevouchers'),(359,'Can change order line vouchers',120,'change_orderlinevouchers'),(360,'Can delete order line vouchers',120,'delete_orderlinevouchers'),(361,'Can add Wish List',121,'add_wishlist'),(362,'Can change Wish List',121,'change_wishlist'),(363,'Can delete Wish List',121,'delete_wishlist'),(364,'Can add Wish list line',122,'add_line'),(365,'Can change Wish list line',122,'change_line'),(366,'Can delete Wish list line',122,'delete_line'),(367,'Can add user social auth',123,'add_usersocialauth'),(368,'Can change user social auth',123,'change_usersocialauth'),(369,'Can delete user social auth',123,'delete_usersocialauth'),(370,'Can add nonce',124,'add_nonce'),(371,'Can change nonce',124,'change_nonce'),(372,'Can delete nonce',124,'delete_nonce'),(373,'Can add association',125,'add_association'),(374,'Can change association',125,'change_association'),(375,'Can delete association',125,'delete_association'),(376,'Can add code',126,'add_code'),(377,'Can change code',126,'change_code'),(378,'Can delete code',126,'delete_code');
UNLOCK TABLES;

DROP TABLE IF EXISTS `auth_group`;
CREATE TABLE `auth_group` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
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

DROP TABLE IF EXISTS `ecommerce_user`;
CREATE TABLE `ecommerce_user` (
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
  `tracking_context` longtext,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
);

LOCK TABLES `ecommerce_user` WRITE;
INSERT INTO `ecommerce_user` VALUES (1,'!CZYlJfXP0NcD43aj7ZALXIXupgnbG4aJADKKOYIo',NULL,0,'ecommerce_worker','','','',1,1,'2017-03-01 23:29:58.245660',NULL,NULL);
UNLOCK TABLES;

DROP TABLE IF EXISTS `ecommerce_user_groups`;
CREATE TABLE `ecommerce_user_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`group_id`),
  KEY `ecommerce_user_groups_group_id_6090bf9742d30982_fk_auth_group_id` (`group_id`),
  CONSTRAINT `ecommerce_user_gro_user_id_2361cfaa2be9a5bb_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`),
  CONSTRAINT `ecommerce_user_groups_group_id_6090bf9742d30982_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`)
) ;

DROP TABLE IF EXISTS `ecommerce_user_user_permissions`;
CREATE TABLE `ecommerce_user_user_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`permission_id`),
  KEY `ecommerce_u_permission_id_29bd724b63b3aaed_fk_auth_permission_id` (`permission_id`),
  CONSTRAINT `ecommerce_u_permission_id_29bd724b63b3aaed_fk_auth_permission_id` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`),
  CONSTRAINT `ecommerce_user_use_user_id_5fe2026e52f077d9_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

LOCK TABLES `ecommerce_user_user_permissions` WRITE;
INSERT INTO `ecommerce_user_user_permissions` VALUES (1,1,155);
UNLOCK TABLES;


DROP TABLE IF EXISTS `address_useraddress`;
CREATE TABLE `address_useraddress` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(64) NOT NULL,
  `first_name` varchar(255) NOT NULL,
  `last_name` varchar(255) NOT NULL,
  `line1` varchar(255) NOT NULL,
  `line2` varchar(255) NOT NULL,
  `line3` varchar(255) NOT NULL,
  `line4` varchar(255) NOT NULL,
  `state` varchar(255) NOT NULL,
  `postcode` varchar(64) NOT NULL,
  `search_text` longtext NOT NULL,
  `phone_number` varchar(128) NOT NULL,
  `notes` longtext NOT NULL,
  `is_default_for_shipping` tinyint(1) NOT NULL,
  `is_default_for_billing` tinyint(1) NOT NULL,
  `num_orders` int(10) unsigned NOT NULL,
  `hash` varchar(255) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `country_id` varchar(2) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `address_useraddress_user_id_733690a214958def_uniq` (`user_id`,`hash`),
  KEY `add_country_id_2b88c9a59bb9e5a6_fk_address_country_iso_3166_1_a2` (`country_id`),
  KEY `address_useraddress_0800fc57` (`hash`),
  CONSTRAINT `add_country_id_2b88c9a59bb9e5a6_fk_address_country_iso_3166_1_a2` FOREIGN KEY (`country_id`) REFERENCES `address_country` (`iso_3166_1_a2`),
  CONSTRAINT `address_useraddres_user_id_243fe927c5df790e_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
);

DROP TABLE IF EXISTS `catalogue_option`;
CREATE TABLE `catalogue_option` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `code` varchar(128) NOT NULL,
  `type` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
);
DROP TABLE IF EXISTS `catalogue_productclass`;
CREATE TABLE `catalogue_productclass` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `slug` varchar(128) NOT NULL,
  `requires_shipping` tinyint(1) NOT NULL,
  `track_stock` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
);

LOCK TABLES `catalogue_productclass` WRITE;
INSERT INTO `catalogue_productclass` VALUES (1,'Seat','seat',0,0),(2,'Coupon','coupon',0,0),(3,'Enrollment Code','enrollment_code',0,0);
UNLOCK TABLES;

DROP TABLE IF EXISTS `courses_course`;
CREATE TABLE `courses_course` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `thumbnail_url` varchar(200),
  `verification_deadline` datetime(6),
  PRIMARY KEY (`id`)
) ;

DROP TABLE IF EXISTS `catalogue_product`;
CREATE TABLE `catalogue_product` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `structure` varchar(10) NOT NULL,
  `upc` varchar(64) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` longtext NOT NULL,
  `rating` double DEFAULT NULL,
  `date_created` datetime(6) NOT NULL,
  `date_updated` datetime(6) NOT NULL,
  `is_discountable` tinyint(1) NOT NULL,
  `parent_id` int(11),
  `product_class_id` int(11),
  `course_id` varchar(255),
  `expires` datetime(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `upc` (`upc`),
  KEY `catalogue_product_2dbcba41` (`slug`),
  KEY `catalogue_product_9474e4b5` (`date_updated`),
  KEY `catalogue_product_6be37982` (`parent_id`),
  KEY `catalogue_product_c6619e6f` (`product_class_id`),
  KEY `catalogue_product_ea134da7` (`course_id`),
  CONSTRAINT `c_product_class_id_423660034e393d81_fk_catalogue_productclass_id` FOREIGN KEY (`product_class_id`) REFERENCES `catalogue_productclass` (`id`),
  CONSTRAINT `catalogue_pro_parent_id_3513f469b6da50ee_fk_catalogue_product_id` FOREIGN KEY (`parent_id`) REFERENCES `catalogue_product` (`id`),
  CONSTRAINT `catalogue_produc_course_id_7cd4bd3c0b10e809_fk_courses_course_id` FOREIGN KEY (`course_id`) REFERENCES `courses_course` (`id`)
);

DROP TABLE IF EXISTS `analytics_productrecord`;
CREATE TABLE `analytics_productrecord` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `num_views` int(10) unsigned NOT NULL,
  `num_basket_additions` int(10) unsigned NOT NULL,
  `num_purchases` int(10) unsigned NOT NULL,
  `score` double NOT NULL,
  `product_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `product_id` (`product_id`),
  KEY `analytics_productrecord_81a5c7b1` (`num_purchases`),
  CONSTRAINT `analytics_pr_product_id_6a783f9d2ad3b0b8_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`)
);

DROP TABLE IF EXISTS `analytics_userproductview`;
CREATE TABLE `analytics_userproductview` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date_created` datetime(6) NOT NULL,
  `product_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `analytics_userproductview_9bea82de` (`product_id`),
  KEY `analytics_userproductview_e8701ad4` (`user_id`),
  CONSTRAINT `analytics_us_product_id_4069af89b2f55c13_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`),
  CONSTRAINT `analytics_userprod_user_id_4087a6b710f8c4b6_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
);

DROP TABLE IF EXISTS `analytics_userrecord`;
CREATE TABLE `analytics_userrecord` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `num_product_views` int(10) unsigned NOT NULL,
  `num_basket_additions` int(10) unsigned NOT NULL,
  `num_orders` int(10) unsigned NOT NULL,
  `num_order_lines` int(10) unsigned NOT NULL,
  `num_order_items` int(10) unsigned NOT NULL,
  `total_spent` decimal(12,2) NOT NULL,
  `date_last_order` datetime(6) DEFAULT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  KEY `analytics_userrecord_29bdb5ea` (`num_orders`),
  KEY `analytics_userrecord_89bb6879` (`num_order_lines`),
  KEY `analytics_userrecord_25cd4b4a` (`num_order_items`),
  CONSTRAINT `analytics_userrecor_user_id_cae614d9855117a_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
);

DROP TABLE IF EXISTS `analytics_usersearch`;
CREATE TABLE `analytics_usersearch` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `query` varchar(255) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `analytics_usersear_user_id_7e760309211b811b_fk_ecommerce_user_id` (`user_id`),
  KEY `analytics_usersearch_1b1cc7f0` (`query`),
  CONSTRAINT `analytics_usersear_user_id_7e760309211b811b_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
);

DROP TABLE IF EXISTS `django_site`;
CREATE TABLE `django_site` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain` varchar(100) NOT NULL,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
);

LOCK TABLES `django_site` WRITE;
INSERT INTO `django_site` VALUES (1,'example.com','example.com');
UNLOCK TABLES;

DROP TABLE IF EXISTS `basket_basket`;
CREATE TABLE `basket_basket` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `status` varchar(128) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `date_merged` datetime(6) DEFAULT NULL,
  `date_submitted` datetime(6) DEFAULT NULL,
  `owner_id` int(11),
  `site_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `basket_basket_5e7b1936` (`owner_id`),
  KEY `basket_basket_9365d6e7` (`site_id`),
  CONSTRAINT `basket_basket_owner_id_74ddb970811da304_fk_ecommerce_user_id` FOREIGN KEY (`owner_id`) REFERENCES `ecommerce_user` (`id`),
  CONSTRAINT `basket_basket_site_id_181f3afc5bf1818f_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`)
);

DROP TABLE IF EXISTS `voucher_voucher`;
CREATE TABLE `voucher_voucher` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `code` varchar(128) NOT NULL,
  `usage` varchar(128) NOT NULL,
  `start_datetime` datetime(6) NOT NULL,
  `end_datetime` datetime(6) NOT NULL,
  `num_basket_additions` int(10) unsigned NOT NULL,
  `num_orders` int(10) unsigned NOT NULL,
  `total_discount` decimal(12,2) NOT NULL,
  `date_created` date NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ;


DROP TABLE IF EXISTS `basket_basket_vouchers`;
CREATE TABLE `basket_basket_vouchers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `basket_id` int(11) NOT NULL,
  `voucher_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `basket_id` (`basket_id`,`voucher_id`),
  KEY `basket_basket__voucher_id_19c9200c130f453a_fk_voucher_voucher_id` (`voucher_id`),
  CONSTRAINT `basket_basket__voucher_id_19c9200c130f453a_fk_voucher_voucher_id` FOREIGN KEY (`voucher_id`) REFERENCES `voucher_voucher` (`id`),
  CONSTRAINT `basket_basket_vou_basket_id_46809860fe0f2349_fk_basket_basket_id` FOREIGN KEY (`basket_id`) REFERENCES `basket_basket` (`id`)
);

DROP TABLE IF EXISTS `basket_basketattributetype`;
CREATE TABLE `basket_basketattributetype` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
);

LOCK TABLES `basket_basketattributetype` WRITE;
INSERT INTO `basket_basketattributetype` VALUES (1,'sailthru_bid');
UNLOCK TABLES;

DROP TABLE IF EXISTS `basket_basketattribute`;
CREATE TABLE `basket_basketattribute` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `value_text` longtext NOT NULL,
  `attribute_type_id` int(11) NOT NULL,
  `basket_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `basket_basketattribute_basket_id_3fd09a582bd20aa4_uniq` (`basket_id`,`attribute_type_id`),
  KEY `basket_basketattribute_d3163989` (`attribute_type_id`),
  KEY `basket_basketattribute_afdeaea9` (`basket_id`),
  CONSTRAINT `D1fb5edd4fb5f09448375a1cd3c4b7a1` FOREIGN KEY (`attribute_type_id`) REFERENCES `basket_basketattributetype` (`id`),
  CONSTRAINT `basket_basketattr_basket_id_1dddefa059d92895_fk_basket_basket_id` FOREIGN KEY (`basket_id`) REFERENCES `basket_basket` (`id`)
);

DROP TABLE IF EXISTS `partner_partner`;
CREATE TABLE `partner_partner` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(128) NOT NULL,
  `name` varchar(128) NOT NULL,
  `short_code` varchar(8) NOT NULL,
  `enable_sailthru` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  UNIQUE KEY `short_code` (`short_code`)
) ;

DROP TABLE IF EXISTS `partner_stockrecord`;
CREATE TABLE `partner_stockrecord` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `partner_sku` varchar(128) NOT NULL,
  `price_currency` varchar(12) NOT NULL,
  `price_excl_tax` decimal(12,2) DEFAULT NULL,
  `price_retail` decimal(12,2) DEFAULT NULL,
  `cost_price` decimal(12,2) DEFAULT NULL,
  `num_in_stock` int(10) unsigned DEFAULT NULL,
  `num_allocated` int(11) DEFAULT NULL,
  `low_stock_threshold` int(10) unsigned DEFAULT NULL,
  `date_created` datetime(6) NOT NULL,
  `date_updated` datetime(6) NOT NULL,
  `partner_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `partner_stockrecord_partner_id_4faf51cd0ce15682_uniq` (`partner_id`,`partner_sku`),
  KEY `partner_stoc_product_id_3aa87eeff9d8a80b_fk_catalogue_product_id` (`product_id`),
  KEY `partner_stockrecord_9474e4b5` (`date_updated`),
  CONSTRAINT `partner_stoc_product_id_3aa87eeff9d8a80b_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`),
  CONSTRAINT `partner_stockr_partner_id_6dc7a684b7bf6856_fk_partner_partner_id` FOREIGN KEY (`partner_id`) REFERENCES `partner_partner` (`id`)
) ;

DROP TABLE IF EXISTS `basket_line`;
CREATE TABLE `basket_line` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `line_reference` varchar(128) NOT NULL,
  `quantity` int(10) unsigned NOT NULL,
  `price_currency` varchar(12) NOT NULL,
  `price_excl_tax` decimal(12,2) DEFAULT NULL,
  `price_incl_tax` decimal(12,2) DEFAULT NULL,
  `date_created` datetime(6) NOT NULL,
  `basket_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `stockrecord_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `basket_line_basket_id_7d0d707a7fd92c45_uniq` (`basket_id`,`line_reference`),
  KEY `basket_line_767217f5` (`line_reference`),
  KEY `basket_line_afdeaea9` (`basket_id`),
  KEY `basket_line_9bea82de` (`product_id`),
  KEY `basket_line_271c5733` (`stockrecord_id`),
  CONSTRAINT `basket_line_basket_id_33f070119c0cd86_fk_basket_basket_id` FOREIGN KEY (`basket_id`) REFERENCES `basket_basket` (`id`),
  CONSTRAINT `basket_line_product_id_283cae99af410be8_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`),
  CONSTRAINT `basket_stockrecord_id_7335383654703c38_fk_partner_stockrecord_id` FOREIGN KEY (`stockrecord_id`) REFERENCES `partner_stockrecord` (`id`)
);

DROP TABLE IF EXISTS `basket_lineattribute`;
CREATE TABLE `basket_lineattribute` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `value` varchar(255) NOT NULL,
  `line_id` int(11) NOT NULL,
  `option_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `basket_lineattribute_line_id_7342a1870e7f4e05_fk_basket_line_id` (`line_id`),
  KEY `basket_lineattribute_28df3725` (`option_id`),
  CONSTRAINT `basket_lineatt_option_id_61a93d0109cbadce_fk_catalogue_option_id` FOREIGN KEY (`option_id`) REFERENCES `catalogue_option` (`id`),
  CONSTRAINT `basket_lineattribute_line_id_7342a1870e7f4e05_fk_basket_line_id` FOREIGN KEY (`line_id`) REFERENCES `basket_line` (`id`)
);

DROP TABLE IF EXISTS `catalogue_catalog`;
CREATE TABLE `catalogue_catalog` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `partner_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `catalogue_cata_partner_id_53a27252e109a075_fk_partner_partner_id` (`partner_id`),
  CONSTRAINT `catalogue_cata_partner_id_53a27252e109a075_fk_partner_partner_id` FOREIGN KEY (`partner_id`) REFERENCES `partner_partner` (`id`)
);

DROP TABLE IF EXISTS `catalogue_attributeoptiongroup`;
CREATE TABLE `catalogue_attributeoptiongroup` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `catalogue_attributeoption`;
CREATE TABLE `catalogue_attributeoption` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `option` varchar(255) NOT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `catalogue_attributeoption_0e939a4f` (`group_id`),
  CONSTRAINT `c_group_id_15d15061b9ea4562_fk_catalogue_attributeoptiongroup_id` FOREIGN KEY (`group_id`) REFERENCES `catalogue_attributeoptiongroup` (`id`)
);

DROP TABLE IF EXISTS `catalogue_catalog_stock_records`;
CREATE TABLE `catalogue_catalog_stock_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `catalog_id` int(11) NOT NULL,
  `stockrecord_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `catalog_id` (`catalog_id`,`stockrecord_id`),
  KEY `catalo_stockrecord_id_10f95d188efaa560_fk_partner_stockrecord_id` (`stockrecord_id`),
  CONSTRAINT `catalo_stockrecord_id_10f95d188efaa560_fk_partner_stockrecord_id` FOREIGN KEY (`stockrecord_id`) REFERENCES `partner_stockrecord` (`id`),
  CONSTRAINT `catalogue_ca_catalog_id_7820c68e954a2310_fk_catalogue_catalog_id` FOREIGN KEY (`catalog_id`) REFERENCES `catalogue_catalog` (`id`)
);

DROP TABLE IF EXISTS `catalogue_category`;
CREATE TABLE `catalogue_category` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `path` varchar(255) NOT NULL,
  `depth` int(10) unsigned NOT NULL,
  `numchild` int(10) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` longtext NOT NULL,
  `image` varchar(255) DEFAULT NULL,
  `slug` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `path` (`path`),
  KEY `catalogue_category_b068931c` (`name`),
  KEY `catalogue_category_2dbcba41` (`slug`)
) ;

LOCK TABLES `catalogue_category` WRITE;
INSERT INTO `catalogue_category` VALUES (1,'0001',1,1,'Seats','All course seats','','seats'),(2,'0002',1,15,'Coupons','All Coupons','','coupons'),(3,'00020001',2,0,'Affiliate Promotion','','','affiliate-promotion'),(4,'00020002',2,0,'Bulk Enrollment','','','bulk-enrollment'),(5,'00020003',2,0,'ConnectEd','','','connected'),(6,'00020004',2,0,'Course Promotion','','','course-promotion'),(7,'00020005',2,0,'Customer Service','','','customer-service'),(8,'00020006',2,0,'Financial Assistance','','','financial-assistance'),(9,'00020007',2,0,'Geography Promotion','','','geography-promotion'),(10,'00020008',2,0,'Marketing Partner Promotion','','','marketing-partner-promotion'),(11,'00020009',2,0,'Marketing-Other','','','marketing-other'),(12,'0002000A',2,0,'Paid Cohort','','','paid-cohort'),(13,'0002000B',2,0,'Other','','','other'),(14,'0002000C',2,0,'Retention Promotion','','','retention-promotion'),(15,'0002000D',2,0,'Services-Other','','','services-other'),(16,'0002000E',2,0,'Support-Other','','','support-other'),(17,'0002000F',2,0,'Upsell Promotion','','','upsell-promotion');
UNLOCK TABLES;

DROP TABLE IF EXISTS `catalogue_historicalproduct`;
CREATE TABLE `catalogue_historicalproduct` (
  `id` int(11) NOT NULL,
  `structure` varchar(10) NOT NULL,
  `upc` varchar(64) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` longtext NOT NULL,
  `rating` double DEFAULT NULL,
  `date_created` datetime(6) NOT NULL,
  `date_updated` datetime(6) NOT NULL,
  `is_discountable` tinyint(1) NOT NULL,
  `history_id` int(11) NOT NULL AUTO_INCREMENT,
  `history_date` datetime(6) NOT NULL,
  `history_type` varchar(1) NOT NULL,
  `course_id` varchar(255) DEFAULT NULL,
  `history_user_id` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `product_class_id` int(11) DEFAULT NULL,
  `expires` datetime(6),
  PRIMARY KEY (`history_id`),
  KEY `catalogue__history_user_id_257030d10a1d3184_fk_ecommerce_user_id` (`history_user_id`),
  KEY `catalogue_historicalproduct_b80bb774` (`id`),
  KEY `catalogue_historicalproduct_2f9e567e` (`upc`),
  KEY `catalogue_historicalproduct_2dbcba41` (`slug`),
  KEY `catalogue_historicalproduct_9474e4b5` (`date_updated`),
  CONSTRAINT `catalogue__history_user_id_257030d10a1d3184_fk_ecommerce_user_id` FOREIGN KEY (`history_user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `catalogue_historicalproductattributevalue`;
CREATE TABLE `catalogue_historicalproductattributevalue` (
  `id` int(11) NOT NULL,
  `value_text` longtext,
  `value_integer` int(11) DEFAULT NULL,
  `value_boolean` tinyint(1) DEFAULT NULL,
  `value_float` double DEFAULT NULL,
  `value_richtext` longtext,
  `value_date` date DEFAULT NULL,
  `value_file` longtext,
  `value_image` longtext,
  `entity_object_id` int(10) unsigned DEFAULT NULL,
  `history_id` int(11) NOT NULL AUTO_INCREMENT,
  `history_date` datetime(6) NOT NULL,
  `history_type` varchar(1) NOT NULL,
  `attribute_id` int(11) DEFAULT NULL,
  `entity_content_type_id` int(11) DEFAULT NULL,
  `history_user_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `value_option_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`history_id`),
  KEY `catalogue__history_user_id_1df684fbc48d669f_fk_ecommerce_user_id` (`history_user_id`),
  KEY `catalogue_historicalproductattributevalue_b80bb774` (`id`),
  CONSTRAINT `catalogue__history_user_id_1df684fbc48d669f_fk_ecommerce_user_id` FOREIGN KEY (`history_user_id`) REFERENCES `ecommerce_user` (`id`)
);

DROP TABLE IF EXISTS `catalogue_product_product_options`;
CREATE TABLE `catalogue_product_product_options` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL,
  `option_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `product_id` (`product_id`,`option_id`),
  KEY `catalogue_prod_option_id_3c86d91145e1eda2_fk_catalogue_option_id` (`option_id`),
  CONSTRAINT `catalogue_pr_product_id_36290bcd1abb306d_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`),
  CONSTRAINT `catalogue_prod_option_id_3c86d91145e1eda2_fk_catalogue_option_id` FOREIGN KEY (`option_id`) REFERENCES `catalogue_option` (`id`)
);

DROP TABLE IF EXISTS `catalogue_productattribute`;
CREATE TABLE `catalogue_productattribute` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `code` varchar(128) NOT NULL,
  `type` varchar(20) NOT NULL,
  `required` tinyint(1) NOT NULL,
  `option_group_id` int(11) DEFAULT NULL,
  `product_class_id` int(11),
  PRIMARY KEY (`id`),
  KEY `ee81dd8e018daf46989580657aa2c5f2` (`option_group_id`),
  KEY `catalogue_productattribute_c1336794` (`code`),
  KEY `catalogue_productattribute_c6619e6f` (`product_class_id`),
  CONSTRAINT `c_product_class_id_1362a591cb94a410_fk_catalogue_productclass_id` FOREIGN KEY (`product_class_id`) REFERENCES `catalogue_productclass` (`id`),
  CONSTRAINT `ee81dd8e018daf46989580657aa2c5f2` FOREIGN KEY (`option_group_id`) REFERENCES `catalogue_attributeoptiongroup` (`id`)
);

LOCK TABLES `catalogue_productattribute` WRITE;
INSERT INTO `catalogue_productattribute` VALUES (1,'course_key','course_key','text',1,NULL,1),(2,'id_verification_required','id_verification_required','boolean',0,NULL,1),(3,'certificate_type','certificate_type','text',0,NULL,1),(4,'credit_provider','credit_provider','text',0,NULL,1),(5,'credit_hours','credit_hours','integer',0,NULL,1),(6,'Coupon vouchers','coupon_vouchers','entity',1,NULL,2),(7,'Note','note','text',0,NULL,2),(8,'Course Key','course_key','text',1,NULL,3),(9,'Seat Type','seat_type','text',1,NULL,3),(10,'id_verification_required','id_verification_required','boolean',0,NULL,3);
UNLOCK TABLES;

DROP TABLE IF EXISTS `catalogue_productattributevalue`;
CREATE TABLE `catalogue_productattributevalue` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `value_text` longtext,
  `value_integer` int(11) DEFAULT NULL,
  `value_boolean` tinyint(1) DEFAULT NULL,
  `value_float` double DEFAULT NULL,
  `value_richtext` longtext,
  `value_date` date DEFAULT NULL,
  `value_file` varchar(255) DEFAULT NULL,
  `value_image` varchar(255) DEFAULT NULL,
  `entity_object_id` int(10) unsigned DEFAULT NULL,
  `attribute_id` int(11) NOT NULL,
  `entity_content_type_id` int(11) DEFAULT NULL,
  `product_id` int(11) NOT NULL,
  `value_option_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `catalogue_productattributeval_attribute_id_2577af51bd9ad6d8_uniq` (`attribute_id`,`product_id`),
  KEY `D0e0df13f5db7d43bdbab175073e15d0` (`entity_content_type_id`),
  KEY `catalogue_pr_product_id_627870505f32fefb_fk_catalogue_product_id` (`product_id`),
  KEY `df82639e31ada55e647d697296f3915a` (`value_option_id`),
  CONSTRAINT `D0e0df13f5db7d43bdbab175073e15d0` FOREIGN KEY (`entity_content_type_id`) REFERENCES `django_content_type` (`id`),
  CONSTRAINT `c_attribute_id_52017edc0eb6d798_fk_catalogue_productattribute_id` FOREIGN KEY (`attribute_id`) REFERENCES `catalogue_productattribute` (`id`),
  CONSTRAINT `catalogue_pr_product_id_627870505f32fefb_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`),
  CONSTRAINT `df82639e31ada55e647d697296f3915a` FOREIGN KEY (`value_option_id`) REFERENCES `catalogue_attributeoption` (`id`)
);

DROP TABLE IF EXISTS `catalogue_productcategory`;
CREATE TABLE `catalogue_productcategory` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `catalogue_productcategory_product_id_5010e6207ddeddfe_uniq` (`product_id`,`category_id`),
  KEY `catalogue__category_id_62892d4b1ea04730_fk_catalogue_category_id` (`category_id`),
  CONSTRAINT `catalogue__category_id_62892d4b1ea04730_fk_catalogue_category_id` FOREIGN KEY (`category_id`) REFERENCES `catalogue_category` (`id`),
  CONSTRAINT `catalogue_pr_product_id_6615a148819eab3a_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`)
);

DROP TABLE IF EXISTS `catalogue_productclass_options`;
CREATE TABLE `catalogue_productclass_options` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `productclass_id` int(11) NOT NULL,
  `option_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `productclass_id` (`productclass_id`,`option_id`),
  KEY `catalogue_prod_option_id_53b23c145a0e7ae1_fk_catalogue_option_id` (`option_id`),
  CONSTRAINT `ca_productclass_id_19b3f6278fef360d_fk_catalogue_productclass_id` FOREIGN KEY (`productclass_id`) REFERENCES `catalogue_productclass` (`id`),
  CONSTRAINT `catalogue_prod_option_id_53b23c145a0e7ae1_fk_catalogue_option_id` FOREIGN KEY (`option_id`) REFERENCES `catalogue_option` (`id`)
);

DROP TABLE IF EXISTS `catalogue_productimage`;
CREATE TABLE `catalogue_productimage` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `original` varchar(255) NOT NULL,
  `caption` varchar(200) NOT NULL,
  `display_order` int(10) unsigned NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `product_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `catalogue_productimage_product_id_13868d064d886d95_uniq` (`product_id`,`display_order`),
  CONSTRAINT `catalogue_pr_product_id_139fa42825e67bb0_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`)
);

DROP TABLE IF EXISTS `catalogue_productrecommendation`;
CREATE TABLE `catalogue_productrecommendation` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ranking` smallint(5) unsigned NOT NULL,
  `primary_id` int(11) NOT NULL,
  `recommendation_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `catalogue_productrecommendation_primary_id_7bcb067d85969ce3_uniq` (`primary_id`,`recommendation_id`),
  KEY `catal_recommendation_id_238400b019a404e0_fk_catalogue_product_id` (`recommendation_id`),
  CONSTRAINT `catal_recommendation_id_238400b019a404e0_fk_catalogue_product_id` FOREIGN KEY (`recommendation_id`) REFERENCES `catalogue_product` (`id`),
  CONSTRAINT `catalogue_pr_primary_id_3ca4b79abcaac002_fk_catalogue_product_id` FOREIGN KEY (`primary_id`) REFERENCES `catalogue_product` (`id`)
);

DROP TABLE IF EXISTS `core_client`;
CREATE TABLE `core_client` (
  `user_ptr_id` int(11) NOT NULL,
  PRIMARY KEY (`user_ptr_id`),
  CONSTRAINT `core_client_user_ptr_id_784121111bb60d22_fk_ecommerce_user_id` FOREIGN KEY (`user_ptr_id`) REFERENCES `ecommerce_user` (`id`)
);

DROP TABLE IF EXISTS `core_siteconfiguration`;
CREATE TABLE `core_siteconfiguration` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lms_url_root` varchar(200) NOT NULL,
  `theme_scss_path` varchar(255) NOT NULL,
  `payment_processors` varchar(255) NOT NULL,
  `partner_id` int(11) NOT NULL,
  `site_id` int(11) NOT NULL,
  `oauth_settings` longtext NOT NULL,
  `segment_key` varchar(255),
  `from_email` varchar(255),
  `enable_enrollment_codes` tinyint(1) NOT NULL,
  `payment_support_email` varchar(255) NOT NULL,
  `payment_support_url` varchar(255) NOT NULL,
  `affiliate_cookie_name` varchar(255) NOT NULL,
  `utm_cookie_name` varchar(255) NOT NULL,
  `enable_otto_receipt_page` tinyint(1) NOT NULL,
  `client_side_payment_processor` varchar(255),
  PRIMARY KEY (`id`),
  UNIQUE KEY `core_siteconfiguration_site_id_6d898a4104ef1631_uniq` (`site_id`,`partner_id`),
  UNIQUE KEY `core_siteconfiguration_site_id_430b5095155db758_uniq` (`site_id`),
  KEY `core_siteconfi_partner_id_6fd09f8adc3aafd8_fk_partner_partner_id` (`partner_id`),
  CONSTRAINT `core_siteconfi_partner_id_6fd09f8adc3aafd8_fk_partner_partner_id` FOREIGN KEY (`partner_id`) REFERENCES `partner_partner` (`id`),
  CONSTRAINT `core_siteconfiguratio_site_id_430b5095155db758_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`)
) ;

DROP TABLE IF EXISTS `courses_historicalcourse`;
CREATE TABLE `courses_historicalcourse` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `history_id` int(11) NOT NULL AUTO_INCREMENT,
  `history_date` datetime(6) NOT NULL,
  `history_type` varchar(1) NOT NULL,
  `history_user_id` int(11) DEFAULT NULL,
  `thumbnail_url` varchar(200),
  `verification_deadline` datetime(6),
  PRIMARY KEY (`history_id`),
  KEY `courses_hi_history_user_id_2c90172d7dfa04da_fk_ecommerce_user_id` (`history_user_id`),
  KEY `courses_historicalcourse_b80bb774` (`id`),
  CONSTRAINT `courses_hi_history_user_id_2c90172d7dfa04da_fk_ecommerce_user_id` FOREIGN KEY (`history_user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `customer_communicationeventtype`;
CREATE TABLE `customer_communicationeventtype` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(128) NOT NULL,
  `name` varchar(255) NOT NULL,
  `category` varchar(255) NOT NULL,
  `email_subject_template` varchar(255) DEFAULT NULL,
  `email_body_template` longtext,
  `email_body_html_template` longtext,
  `sms_template` varchar(170) DEFAULT NULL,
  `date_created` datetime(6) NOT NULL,
  `date_updated` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ;

DROP TABLE IF EXISTS `customer_email`;
CREATE TABLE `customer_email` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `subject` longtext NOT NULL,
  `body_text` longtext NOT NULL,
  `body_html` longtext NOT NULL,
  `date_sent` datetime(6) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `customer_email_user_id_8eeb3a31aa9371c_fk_ecommerce_user_id` (`user_id`),
  CONSTRAINT `customer_email_user_id_8eeb3a31aa9371c_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `customer_notification`;
CREATE TABLE `customer_notification` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `subject` varchar(255) NOT NULL,
  `body` longtext NOT NULL,
  `category` varchar(255) NOT NULL,
  `location` varchar(32) NOT NULL,
  `date_sent` datetime(6) NOT NULL,
  `date_read` datetime(6) DEFAULT NULL,
  `recipient_id` int(11) NOT NULL,
  `sender_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `customer_noti_recipient_id_2a3e81b6f1125b41_fk_ecommerce_user_id` (`recipient_id`),
  KEY `customer_notific_sender_id_327cbc8fe9128da8_fk_ecommerce_user_id` (`sender_id`),
  CONSTRAINT `customer_noti_recipient_id_2a3e81b6f1125b41_fk_ecommerce_user_id` FOREIGN KEY (`recipient_id`) REFERENCES `ecommerce_user` (`id`),
  CONSTRAINT `customer_notific_sender_id_327cbc8fe9128da8_fk_ecommerce_user_id` FOREIGN KEY (`sender_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `customer_productalert`;
CREATE TABLE `customer_productalert` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(75) NOT NULL,
  `key` varchar(128) NOT NULL,
  `status` varchar(20) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `date_confirmed` datetime(6) DEFAULT NULL,
  `date_cancelled` datetime(6) DEFAULT NULL,
  `date_closed` datetime(6) DEFAULT NULL,
  `product_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `customer_pro_product_id_76d688fb01b70d57_fk_catalogue_product_id` (`product_id`),
  KEY `customer_productal_user_id_6fc3d0dd9c8130b4_fk_ecommerce_user_id` (`user_id`),
  KEY `customer_productalert_0c83f57c` (`email`),
  KEY `customer_productalert_3c6e0b8a` (`key`),
  CONSTRAINT `customer_pro_product_id_76d688fb01b70d57_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`),
  CONSTRAINT `customer_productal_user_id_6fc3d0dd9c8130b4_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

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
  KEY `django_admin_log_user_id_52fdd58701c5f563_fk_ecommerce_user_id` (`user_id`),
  CONSTRAINT `djang_content_type_id_697914295151027a_fk_django_content_type_id` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`),
  CONSTRAINT `django_admin_log_user_id_52fdd58701c5f563_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `django_flatpage`;
CREATE TABLE `django_flatpage` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(100) NOT NULL,
  `title` varchar(200) NOT NULL,
  `content` longtext NOT NULL,
  `enable_comments` tinyint(1) NOT NULL,
  `template_name` varchar(70) NOT NULL,
  `registration_required` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `django_flatpage_572d4e42` (`url`)
) ;

DROP TABLE IF EXISTS `django_flatpage_sites`;
CREATE TABLE `django_flatpage_sites` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `flatpage_id` int(11) NOT NULL,
  `site_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `flatpage_id` (`flatpage_id`,`site_id`),
  KEY `django_flatpage_sites_site_id_481dafa7c6e850d9_fk_django_site_id` (`site_id`),
  CONSTRAINT `django_flatpa_flatpage_id_7b4e76c0a3a9d13a_fk_django_flatpage_id` FOREIGN KEY (`flatpage_id`) REFERENCES `django_flatpage` (`id`),
  CONSTRAINT `django_flatpage_sites_site_id_481dafa7c6e850d9_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`)
) ;

DROP TABLE IF EXISTS `django_migrations`;
CREATE TABLE `django_migrations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `applied` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
);

LOCK TABLES `django_migrations` WRITE;
INSERT INTO `django_migrations` VALUES (1,'contenttypes','0001_initial','2017-03-01 23:28:12.645463'),(2,'auth','0001_initial','2017-03-01 23:28:14.066489'),(3,'core','0001_initial','2017-03-01 23:28:15.678756'),(4,'address','0001_initial','2017-03-01 23:28:16.987147'),(5,'admin','0001_initial','2017-03-01 23:28:17.788457'),(6,'catalogue','0001_initial','2017-03-01 23:28:28.597953'),(7,'analytics','0001_initial','2017-03-01 23:28:30.488480'),(8,'analytics','0002_auto_20140827_1705','2017-03-01 23:28:32.693191'),(9,'contenttypes','0002_remove_content_type_name','2017-03-01 23:28:33.444085'),(10,'auth','0002_alter_permission_name_max_length','2017-03-01 23:28:33.880732'),(11,'auth','0003_alter_user_email_max_length','2017-03-01 23:28:34.048233'),(12,'auth','0004_alter_user_username_opts','2017-03-01 23:28:34.185780'),(13,'auth','0005_alter_user_last_login_null','2017-03-01 23:28:34.330027'),(14,'auth','0006_require_contenttypes_0002','2017-03-01 23:28:34.348858'),(15,'sites','0001_initial','2017-03-01 23:28:34.521725'),(16,'partner','0001_initial','2017-03-01 23:28:38.490080'),(17,'customer','0001_initial','2017-03-01 23:28:41.193791'),(18,'basket','0001_initial','2017-03-01 23:28:42.053430'),(19,'basket','0002_auto_20140827_1705','2017-03-01 23:28:46.379489'),(20,'order','0001_initial','2017-03-01 23:29:09.068199'),(21,'offer','0001_initial','2017-03-01 23:29:17.238098'),(22,'voucher','0001_initial','2017-03-01 23:29:19.772302'),(23,'basket','0003_basket_vouchers','2017-03-01 23:29:20.786421'),(24,'basket','0004_auto_20141007_2032','2017-03-01 23:29:21.161588'),(25,'basket','0005_auto_20150709_1205','2017-03-01 23:29:22.255990'),(26,'basket','0006_basket_site','2017-03-01 23:29:23.178788'),(27,'basket','0007_auto_20160907_2040','2017-03-01 23:29:25.489657'),(28,'partner','0002_auto_20141007_2032','2017-03-01 23:29:25.865187'),(29,'partner','0003_auto_20150223_1130','2017-03-01 23:29:25.895558'),(30,'courses','0001_initial','2017-03-01 23:29:26.083779'),(31,'catalogue','0002_auto_20150223_1052','2017-03-01 23:29:26.161944'),(32,'catalogue','0003_product_course','2017-03-01 23:29:27.301039'),(33,'catalogue','0004_auto_20150609_0129','2017-03-01 23:29:31.583270'),(34,'partner','0004_auto_20150609_1215','2017-03-01 23:29:35.082870'),(35,'partner','0005_auto_20150610_1355','2017-03-01 23:29:36.208774'),(36,'partner','0006_auto_20150709_1205','2017-03-01 23:29:37.255427'),(37,'partner','0007_auto_20150914_0841','2017-03-01 23:29:38.061456'),(38,'partner','0008_auto_20150914_1057','2017-03-01 23:29:38.694112'),(39,'catalogue','0005_auto_20150610_1355','2017-03-01 23:29:41.052382'),(40,'catalogue','0006_credit_provider_attr','2017-03-01 23:29:41.130259'),(41,'catalogue','0007_auto_20150709_1205','2017-03-01 23:29:43.246973'),(42,'catalogue','0008_auto_20150709_1254','2017-03-01 23:29:44.458379'),(43,'catalogue','0009_credit_hours_attr','2017-03-01 23:29:44.551860'),(44,'catalogue','0010_catalog','2017-03-01 23:29:46.050482'),(45,'catalogue','0011_auto_20151019_0639','2017-03-01 23:29:47.066492'),(46,'catalogue','0012_enrollment_code_product_class','2017-03-01 23:29:47.098235'),(47,'catalogue','0013_coupon_product_class','2017-03-01 23:29:47.222151'),(48,'catalogue','0014_alter_couponvouchers_attribute','2017-03-01 23:29:47.307185'),(49,'catalogue','0015_default_categories','2017-03-01 23:29:47.492560'),(50,'catalogue','0016_coupon_note_attribute','2017-03-01 23:29:47.566326'),(51,'catalogue','0017_enrollment_code_product_class','2017-03-01 23:29:47.648778'),(52,'catalogue','0018_auto_20160530_0134','2017-03-01 23:29:47.959224'),(53,'catalogue','0019_enrollment_code_idverifyreq_attribute','2017-03-01 23:29:48.038622'),(54,'catalogue','0020_auto_20161025_1446','2017-03-01 23:29:48.392062'),(55,'waffle','0001_initial','2017-03-01 23:29:50.895974'),(56,'core','0002_auto_20150826_1455','2017-03-01 23:29:54.017919'),(57,'core','0003_auto_20150914_1120','2017-03-01 23:29:55.662257'),(58,'core','0004_auto_20150915_1023','2017-03-01 23:29:58.119771'),(59,'core','0005_auto_20150924_0123','2017-03-01 23:29:58.195074'),(60,'core','0006_add_service_user','2017-03-01 23:29:58.272637'),(61,'core','0007_auto_20151005_1333','2017-03-01 23:29:58.370967'),(62,'core','0008_client','2017-03-01 23:29:59.053772'),(63,'core','0009_service_user_privileges','2017-03-01 23:29:59.385604'),(64,'core','0010_add_async_sample','2017-03-01 23:29:59.459853'),(65,'core','0011_siteconfiguration_oauth_settings','2017-03-01 23:30:00.022913'),(66,'core','0012_businessclient','2017-03-01 23:30:00.227310'),(67,'core','0013_siteconfiguration_segment_key','2017-03-01 23:30:00.804453'),(68,'core','0014_enrollment_code_switch','2017-03-01 23:30:00.913450'),(69,'core','0015_siteconfiguration_from_email','2017-03-01 23:30:01.552982'),(70,'core','0016_siteconfiguration_enable_enrollment_codes','2017-03-01 23:30:02.255403'),(71,'core','0017_siteconfiguration_payment_support_email','2017-03-01 23:30:02.851970'),(72,'core','0018_siteconfiguration_payment_support_url','2017-03-01 23:30:03.461036'),(73,'core','0019_auto_20161012_1404','2017-03-01 23:30:04.617177'),(74,'core','0020_siteconfiguration_enable_otto_receipt_page','2017-03-01 23:30:05.240960'),(75,'core','0021_siteconfiguration_client_side_payment_processor','2017-03-01 23:30:05.880926'),(76,'core','0022_auto_20161108_2101','2017-03-01 23:30:06.303410'),(77,'courses','0002_historicalcourse','2017-03-01 23:30:07.312378'),(78,'courses','0003_auto_20150618_1108','2017-03-01 23:30:08.491585'),(79,'courses','0004_auto_20150803_1406','2017-03-01 23:30:09.773141'),(80,'customer','0002_auto_20160517_0930','2017-03-01 23:30:10.169015'),(81,'flatpages','0001_initial','2017-03-01 23:30:11.645396'),(82,'order','0002_auto_20141007_2032','2017-03-01 23:30:12.132698'),(83,'order','0003_auto_20150224_1520','2017-03-01 23:30:12.192812'),(84,'order','0004_order_payment_processor','2017-03-01 23:30:12.961005'),(85,'order','0005_deprecate_order_payment_processor','2017-03-01 23:30:13.694990'),(86,'order','0006_paymentevent_processor_name','2017-03-01 23:30:14.413543'),(87,'order','0007_create_history_tables','2017-03-01 23:30:16.630221'),(88,'order','0008_delete_order_payment_processor','2017-03-01 23:30:18.008877'),(89,'order','0009_auto_20150709_1205','2017-03-01 23:30:18.935763'),(90,'invoice','0001_initial','2017-03-01 23:30:22.536690'),(91,'invoice','0002_auto_20160324_1919','2017-03-01 23:30:26.958180'),(92,'invoice','0003_auto_20160616_0657','2017-03-01 23:30:34.944123'),(93,'offer','0002_range_catalog','2017-03-01 23:30:36.161239'),(94,'offer','0003_auto_20160517_1247','2017-03-01 23:30:37.586546'),(95,'offer','0004_auto_20160530_0944','2017-03-01 23:30:38.352809'),(96,'offer','0005_conditionaloffer_email_domains','2017-03-01 23:30:39.070174'),(97,'offer','0006_auto_20161025_1446','2017-03-01 23:30:39.535243'),(98,'offer','0007_auto_20161026_0856','2017-03-01 23:30:40.385217'),(99,'order','0010_auto_20160529_2245','2017-03-01 23:30:40.893081'),(100,'order','0011_auto_20161025_1446','2017-03-01 23:30:41.333303'),(101,'partner','0009_partner_enable_sailthru','2017-03-01 23:30:43.806980'),(102,'partner','0010_auto_20161025_1446','2017-03-01 23:30:44.134657'),(103,'payment','0001_initial','2017-03-01 23:30:48.023114'),(104,'payment','0002_auto_20141007_2032','2017-03-01 23:30:48.524869'),(105,'payment','0003_create_payment_processor_response','2017-03-01 23:30:50.037869'),(106,'payment','0004_source_card_type','2017-03-01 23:30:50.725484'),(107,'payment','0005_paypalwebprofile','2017-03-01 23:30:50.931373'),(108,'payment','0006_enable_payment_processors','2017-03-01 23:30:51.025705'),(109,'payment','0007_add_cybersource_level23_sample','2017-03-01 23:30:51.118857'),(110,'payment','0008_remove_cybersource_level23_sample','2017-03-01 23:30:51.194877'),(111,'payment','0009_auto_20161025_1446','2017-03-01 23:30:51.656592'),(112,'payment','0010_create_client_side_checkout_flag','2017-03-01 23:30:51.787160'),(113,'payment','0011_paypalprocessorconfiguration','2017-03-01 23:30:51.990847'),(114,'payment','0012_auto_20161109_1456','2017-03-01 23:30:52.043556'),(115,'promotions','0001_initial','2017-03-01 23:31:00.913633'),(116,'promotions','0002_auto_20150604_1450','2017-03-01 23:31:02.162071'),(117,'referrals','0001_initial','2017-03-01 23:31:03.414556'),(118,'referrals','0002_auto_20161011_1728','2017-03-01 23:31:11.318660'),(119,'referrals','0003_auto_20161027_1738','2017-03-01 23:31:12.179465'),(120,'refund','0001_squashed_0002_auto_20150515_2220','2017-03-01 23:31:17.552441'),(121,'refund','0002_auto_20151214_1017','2017-03-01 23:31:19.480789'),(122,'reviews','0001_initial','2017-03-01 23:31:23.475727'),(123,'sailthru','0001_initial','2017-03-01 23:31:23.553930'),(124,'sailthru','0002_add_basket_attribute_type','2017-03-01 23:31:23.633433'),(125,'sessions','0001_initial','2017-03-01 23:31:23.904785'),(126,'shipping','0001_initial','2017-03-01 23:31:28.367727'),(127,'shipping','0002_auto_20150604_1450','2017-03-01 23:31:31.024464'),(128,'default','0001_initial','2017-03-01 23:31:35.196978'),(129,'default','0002_add_related_name','2017-03-01 23:31:36.070041'),(130,'default','0003_alter_email_max_length','2017-03-01 23:31:36.444647'),(131,'default','0004_auto_20160423_0400','2017-03-01 23:31:36.987271'),(132,'social_auth','0005_auto_20160727_2333','2017-03-01 23:31:37.195214'),(133,'theming','0001_initial','2017-03-01 23:31:38.195424'),(134,'voucher','0002_couponvouchers','2017-03-01 23:31:39.913645'),(135,'voucher','0003_orderlinevouchers','2017-03-01 23:31:41.724672'),(136,'voucher','0004_auto_20160517_0930','2017-03-01 23:31:42.994250'),(137,'wishlists','0001_initial','2017-03-01 23:31:47.038698'),(138,'social_auth','0001_initial','2017-03-01 23:31:47.075900'),(139,'social_auth','0003_alter_email_max_length','2017-03-01 23:31:47.099198'),(140,'social_auth','0004_auto_20160423_0400','2017-03-01 23:31:47.130410'),(141,'social_auth','0002_add_related_name','2017-03-01 23:31:47.161920');
UNLOCK TABLES;

DROP TABLE IF EXISTS `django_session`;
CREATE TABLE `django_session` (
  `session_key` varchar(40) NOT NULL,
  `session_data` longtext NOT NULL,
  `expire_date` datetime(6) NOT NULL,
  PRIMARY KEY (`session_key`),
  KEY `django_session_de54fa62` (`expire_date`)
) ;

DROP TABLE IF EXISTS `invoice_historicalinvoice`;
CREATE TABLE `invoice_historicalinvoice` (
  `id` int(11) NOT NULL,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  `state` varchar(255) NOT NULL,
  `history_id` int(11) NOT NULL AUTO_INCREMENT,
  `history_date` datetime(6) NOT NULL,
  `history_type` varchar(1) NOT NULL,
  `basket_id` int(11) DEFAULT NULL,
  `history_user_id` int(11) DEFAULT NULL,
  `business_client_id` int(11),
  `order_id` int(11),
  `discount_type` varchar(255),
  `discount_value` int(10) unsigned,
  `number` varchar(255),
  `payment_date` datetime(6),
  `tax_deducted_source` int(10) unsigned,
  `type` varchar(255),
  PRIMARY KEY (`history_id`),
  KEY `invoice_his_history_user_id_247d98979ddffd8_fk_ecommerce_user_id` (`history_user_id`),
  KEY `invoice_historicalinvoice_b80bb774` (`id`),
  KEY `invoice_historicalinvoice_8b99fbf1` (`business_client_id`),
  KEY `invoice_historicalinvoice_69dfcb07` (`order_id`),
  CONSTRAINT `invoice_his_history_user_id_247d98979ddffd8_fk_ecommerce_user_id` FOREIGN KEY (`history_user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `core_businessclient`;
CREATE TABLE `core_businessclient` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
);

DROP TABLE IF EXISTS `order_shippingaddress`;
CREATE TABLE `order_shippingaddress` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(64) NOT NULL,
  `first_name` varchar(255) NOT NULL,
  `last_name` varchar(255) NOT NULL,
  `line1` varchar(255) NOT NULL,
  `line2` varchar(255) NOT NULL,
  `line3` varchar(255) NOT NULL,
  `line4` varchar(255) NOT NULL,
  `state` varchar(255) NOT NULL,
  `postcode` varchar(64) NOT NULL,
  `search_text` longtext NOT NULL,
  `phone_number` varchar(128) NOT NULL,
  `notes` longtext NOT NULL,
  `country_id` varchar(2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ord_country_id_7c66bd4e282d4fcf_fk_address_country_iso_3166_1_a2` (`country_id`),
  CONSTRAINT `ord_country_id_7c66bd4e282d4fcf_fk_address_country_iso_3166_1_a2` FOREIGN KEY (`country_id`) REFERENCES `address_country` (`iso_3166_1_a2`)
) ;

DROP TABLE IF EXISTS `order_billingaddress`;
CREATE TABLE `order_billingaddress` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(64) NOT NULL,
  `first_name` varchar(255) NOT NULL,
  `last_name` varchar(255) NOT NULL,
  `line1` varchar(255) NOT NULL,
  `line2` varchar(255) NOT NULL,
  `line3` varchar(255) NOT NULL,
  `line4` varchar(255) NOT NULL,
  `state` varchar(255) NOT NULL,
  `postcode` varchar(64) NOT NULL,
  `search_text` longtext NOT NULL,
  `country_id` varchar(2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ord_country_id_3748ef9a5677c2c1_fk_address_country_iso_3166_1_a2` (`country_id`),
  CONSTRAINT `ord_country_id_3748ef9a5677c2c1_fk_address_country_iso_3166_1_a2` FOREIGN KEY (`country_id`) REFERENCES `address_country` (`iso_3166_1_a2`)
) ;

DROP TABLE IF EXISTS `order_order`;
CREATE TABLE `order_order` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `number` varchar(128) NOT NULL,
  `currency` varchar(12) NOT NULL,
  `total_incl_tax` decimal(12,2) NOT NULL,
  `total_excl_tax` decimal(12,2) NOT NULL,
  `shipping_incl_tax` decimal(12,2) NOT NULL,
  `shipping_excl_tax` decimal(12,2) NOT NULL,
  `shipping_method` varchar(128) NOT NULL,
  `shipping_code` varchar(128) NOT NULL,
  `status` varchar(100) NOT NULL,
  `guest_email` varchar(75) NOT NULL,
  `date_placed` datetime(6) NOT NULL,
  `basket_id` int(11) DEFAULT NULL,
  `billing_address_id` int(11) DEFAULT NULL,
  `shipping_address_id` int(11),
  `site_id` int(11),
  `user_id` int(11),
  PRIMARY KEY (`id`),
  UNIQUE KEY `number` (`number`),
  KEY `order_order_basket_id_3fdb3912d02cb39c_fk_basket_basket_id` (`basket_id`),
  KEY `o_billing_address_id_413696bbd40ac2ff_fk_order_billingaddress_id` (`billing_address_id`),
  KEY `order_order_90e84921` (`date_placed`),
  KEY `order_order_8fb9ffec` (`shipping_address_id`),
  KEY `order_order_9365d6e7` (`site_id`),
  KEY `order_order_e8701ad4` (`user_id`),
  CONSTRAINT `D94ae911c3671773e2202bbfca3ffb8e` FOREIGN KEY (`shipping_address_id`) REFERENCES `order_shippingaddress` (`id`),
  CONSTRAINT `o_billing_address_id_413696bbd40ac2ff_fk_order_billingaddress_id` FOREIGN KEY (`billing_address_id`) REFERENCES `order_billingaddress` (`id`),
  CONSTRAINT `order_order_basket_id_3fdb3912d02cb39c_fk_basket_basket_id` FOREIGN KEY (`basket_id`) REFERENCES `basket_basket` (`id`),
  CONSTRAINT `order_order_site_id_7c5b367997322009_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`),
  CONSTRAINT `order_order_user_id_350d9d363b4b7f2f_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `invoice_invoice`;
CREATE TABLE `invoice_invoice` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  `state` varchar(255) NOT NULL,
  `basket_id` int(11) DEFAULT NULL,
  `business_client_id` int(11),
  `order_id` int(11),
  `discount_type` varchar(255),
  `discount_value` int(10) unsigned,
  `number` varchar(255),
  `payment_date` datetime(6),
  `tax_deducted_source` int(10) unsigned,
  `type` varchar(255),
  PRIMARY KEY (`id`),
  KEY `invoice_invoice_basket_id_93d8600326c64b0_fk_basket_basket_id` (`basket_id`),
  KEY `invoice_invoice_8b99fbf1` (`business_client_id`),
  KEY `invoice_invoice_69dfcb07` (`order_id`),
  CONSTRAINT `in_business_client_id_67ae380b607560f7_fk_core_businessclient_id` FOREIGN KEY (`business_client_id`) REFERENCES `core_businessclient` (`id`),
  CONSTRAINT `invoice_invoice_basket_id_93d8600326c64b0_fk_basket_basket_id` FOREIGN KEY (`basket_id`) REFERENCES `basket_basket` (`id`),
  CONSTRAINT `invoice_invoice_order_id_751dfefc4ed10c11_fk_order_order_id` FOREIGN KEY (`order_id`) REFERENCES `order_order` (`id`)
) ;

DROP TABLE IF EXISTS `offer_range`;
CREATE TABLE `offer_range` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `slug` varchar(128) NOT NULL,
  `description` longtext NOT NULL,
  `is_public` tinyint(1) NOT NULL,
  `includes_all_products` tinyint(1) NOT NULL,
  `proxy_class` varchar(255) DEFAULT NULL,
  `date_created` datetime(6) NOT NULL,
  `catalog_id` int(11),
  `catalog_query` longtext,
  `course_seat_types` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `slug` (`slug`),
  UNIQUE KEY `proxy_class` (`proxy_class`),
  KEY `offer_range_89ed0239` (`catalog_id`),
  CONSTRAINT `offer_range_catalog_id_954e143d34bea09_fk_catalogue_catalog_id` FOREIGN KEY (`catalog_id`) REFERENCES `catalogue_catalog` (`id`)
) ;


DROP TABLE IF EXISTS `offer_benefit`;
CREATE TABLE `offer_benefit` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(128) NOT NULL,
  `value` decimal(12,2) DEFAULT NULL,
  `max_affected_items` int(10) unsigned DEFAULT NULL,
  `proxy_class` varchar(255) DEFAULT NULL,
  `range_id` int(11),
  PRIMARY KEY (`id`),
  UNIQUE KEY `proxy_class` (`proxy_class`),
  KEY `offer_benefit_ee6537b7` (`range_id`),
  CONSTRAINT `offer_benefit_range_id_449c339162094d2d_fk_offer_range_id` FOREIGN KEY (`range_id`) REFERENCES `offer_range` (`id`)
) ;

DROP TABLE IF EXISTS `offer_condition`;
CREATE TABLE `offer_condition` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(128) NOT NULL,
  `value` decimal(12,2) DEFAULT NULL,
  `proxy_class` varchar(255) DEFAULT NULL,
  `range_id` int(11),
  PRIMARY KEY (`id`),
  UNIQUE KEY `proxy_class` (`proxy_class`),
  KEY `offer_condition_ee6537b7` (`range_id`),
  CONSTRAINT `offer_condition_range_id_33cd055e7a47188b_fk_offer_range_id` FOREIGN KEY (`range_id`) REFERENCES `offer_range` (`id`)
) ;

DROP TABLE IF EXISTS `offer_conditionaloffer`;
CREATE TABLE `offer_conditionaloffer` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `slug` varchar(128) NOT NULL,
  `description` longtext NOT NULL,
  `offer_type` varchar(128) NOT NULL,
  `status` varchar(64) NOT NULL,
  `priority` int(11) NOT NULL,
  `start_datetime` datetime(6) DEFAULT NULL,
  `end_datetime` datetime(6) DEFAULT NULL,
  `max_global_applications` int(10) unsigned DEFAULT NULL,
  `max_user_applications` int(10) unsigned DEFAULT NULL,
  `max_basket_applications` int(10) unsigned DEFAULT NULL,
  `max_discount` decimal(12,2) DEFAULT NULL,
  `total_discount` decimal(12,2) NOT NULL,
  `num_applications` int(10) unsigned NOT NULL,
  `num_orders` int(10) unsigned NOT NULL,
  `redirect_url` varchar(200) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `benefit_id` int(11) NOT NULL,
  `condition_id` int(11) NOT NULL,
  `email_domains` varchar(255),
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `slug` (`slug`),
  KEY `offer_conditiona_benefit_id_4c6a38cd195b8af3_fk_offer_benefit_id` (`benefit_id`),
  KEY `offer_condit_condition_id_542cc60fe002425b_fk_offer_condition_id` (`condition_id`),
  CONSTRAINT `offer_condit_condition_id_542cc60fe002425b_fk_offer_condition_id` FOREIGN KEY (`condition_id`) REFERENCES `offer_condition` (`id`),
  CONSTRAINT `offer_conditiona_benefit_id_4c6a38cd195b8af3_fk_offer_benefit_id` FOREIGN KEY (`benefit_id`) REFERENCES `offer_benefit` (`id`)
) ;

DROP TABLE IF EXISTS `offer_range_classes`;
CREATE TABLE `offer_range_classes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `range_id` int(11) NOT NULL,
  `productclass_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `range_id` (`range_id`,`productclass_id`),
  KEY `of_productclass_id_65f7da29711eeec3_fk_catalogue_productclass_id` (`productclass_id`),
  CONSTRAINT `of_productclass_id_65f7da29711eeec3_fk_catalogue_productclass_id` FOREIGN KEY (`productclass_id`) REFERENCES `catalogue_productclass` (`id`),
  CONSTRAINT `offer_range_classes_range_id_5495157c5dba3c7e_fk_offer_range_id` FOREIGN KEY (`range_id`) REFERENCES `offer_range` (`id`)
) ;

DROP TABLE IF EXISTS `offer_range_excluded_products`;
CREATE TABLE `offer_range_excluded_products` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `range_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `range_id` (`range_id`,`product_id`),
  KEY `offer_range__product_id_2f40e4200a81b141_fk_catalogue_product_id` (`product_id`),
  CONSTRAINT `offer_range__product_id_2f40e4200a81b141_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`),
  CONSTRAINT `offer_range_excluded_range_id_5abba188eab514d5_fk_offer_range_id` FOREIGN KEY (`range_id`) REFERENCES `offer_range` (`id`)
) ;

DROP TABLE IF EXISTS `offer_range_included_categories`;
CREATE TABLE `offer_range_included_categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `range_id` int(11) NOT NULL,
  `category_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `range_id` (`range_id`,`category_id`),
  KEY `offer_rang_category_id_19d122d4c8545b33_fk_catalogue_category_id` (`category_id`),
  CONSTRAINT `offer_rang_category_id_19d122d4c8545b33_fk_catalogue_category_id` FOREIGN KEY (`category_id`) REFERENCES `catalogue_category` (`id`),
  CONSTRAINT `offer_range_included__range_id_1b1a361d9d238ad_fk_offer_range_id` FOREIGN KEY (`range_id`) REFERENCES `offer_range` (`id`)
) ;

DROP TABLE IF EXISTS `offer_rangeproduct`;
CREATE TABLE `offer_rangeproduct` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `display_order` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `range_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `offer_rangeproduct_range_id_5c42c8babf2c26b_uniq` (`range_id`,`product_id`),
  KEY `offer_rangep_product_id_6adb31809117d5c3_fk_catalogue_product_id` (`product_id`),
  CONSTRAINT `offer_rangep_product_id_6adb31809117d5c3_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`),
  CONSTRAINT `offer_rangeproduct_range_id_3bd65d61f6fb09df_fk_offer_range_id` FOREIGN KEY (`range_id`) REFERENCES `offer_range` (`id`)
) ;

DROP TABLE IF EXISTS `offer_rangeproductfileupload`;
CREATE TABLE `offer_rangeproductfileupload` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `filepath` varchar(255) NOT NULL,
  `size` int(10) unsigned NOT NULL,
  `date_uploaded` datetime(6) NOT NULL,
  `status` varchar(32) NOT NULL,
  `error_message` varchar(255) NOT NULL,
  `date_processed` datetime(6) DEFAULT NULL,
  `num_new_skus` int(10) unsigned DEFAULT NULL,
  `num_unknown_skus` int(10) unsigned DEFAULT NULL,
  `num_duplicate_skus` int(10) unsigned DEFAULT NULL,
  `range_id` int(11) NOT NULL,
  `uploaded_by_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `offer_rangeproductfi_range_id_50ea275ceeecc99c_fk_offer_range_id` (`range_id`),
  KEY `offer_range_uploaded_by_id_7e7a62fa1b3f0c59_fk_ecommerce_user_id` (`uploaded_by_id`),
  CONSTRAINT `offer_range_uploaded_by_id_7e7a62fa1b3f0c59_fk_ecommerce_user_id` FOREIGN KEY (`uploaded_by_id`) REFERENCES `ecommerce_user` (`id`),
  CONSTRAINT `offer_rangeproductfi_range_id_50ea275ceeecc99c_fk_offer_range_id` FOREIGN KEY (`range_id`) REFERENCES `offer_range` (`id`)
) ;

DROP TABLE IF EXISTS `order_communicationevent`;
CREATE TABLE `order_communicationevent` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date_created` datetime(6) NOT NULL,
  `event_type_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `f3c44c0cdb976b5625481f2fdede8f57` (`event_type_id`),
  KEY `order_communicationevent_69dfcb07` (`order_id`),
  CONSTRAINT `f3c44c0cdb976b5625481f2fdede8f57` FOREIGN KEY (`event_type_id`) REFERENCES `customer_communicationeventtype` (`id`),
  CONSTRAINT `order_communicatione_order_id_500bca2fc2baacb0_fk_order_order_id` FOREIGN KEY (`order_id`) REFERENCES `order_order` (`id`)
) ;

DROP TABLE IF EXISTS `order_historicalline`;
CREATE TABLE `order_historicalline` (
  `id` int(11) NOT NULL,
  `partner_name` varchar(128) NOT NULL,
  `partner_sku` varchar(128) NOT NULL,
  `partner_line_reference` varchar(128) NOT NULL,
  `partner_line_notes` longtext NOT NULL,
  `title` varchar(255) NOT NULL,
  `upc` varchar(128) DEFAULT NULL,
  `quantity` int(10) unsigned NOT NULL,
  `line_price_incl_tax` decimal(12,2) NOT NULL,
  `line_price_excl_tax` decimal(12,2) NOT NULL,
  `line_price_before_discounts_incl_tax` decimal(12,2) NOT NULL,
  `line_price_before_discounts_excl_tax` decimal(12,2) NOT NULL,
  `unit_cost_price` decimal(12,2) DEFAULT NULL,
  `unit_price_incl_tax` decimal(12,2) DEFAULT NULL,
  `unit_price_excl_tax` decimal(12,2) DEFAULT NULL,
  `unit_retail_price` decimal(12,2) DEFAULT NULL,
  `status` varchar(255) NOT NULL,
  `est_dispatch_date` date DEFAULT NULL,
  `history_id` int(11) NOT NULL AUTO_INCREMENT,
  `history_date` datetime(6) NOT NULL,
  `history_type` varchar(1) NOT NULL,
  `history_user_id` int(11) DEFAULT NULL,
  `order_id` int(11) DEFAULT NULL,
  `partner_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `stockrecord_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`history_id`),
  KEY `order_histo_history_user_id_e935ed524492409_fk_ecommerce_user_id` (`history_user_id`),
  KEY `order_historicalline_b80bb774` (`id`),
  CONSTRAINT `order_histo_history_user_id_e935ed524492409_fk_ecommerce_user_id` FOREIGN KEY (`history_user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `order_historicalorder`;
CREATE TABLE `order_historicalorder` (
  `id` int(11) NOT NULL,
  `number` varchar(128) NOT NULL,
  `currency` varchar(12) NOT NULL,
  `total_incl_tax` decimal(12,2) NOT NULL,
  `total_excl_tax` decimal(12,2) NOT NULL,
  `shipping_incl_tax` decimal(12,2) NOT NULL,
  `shipping_excl_tax` decimal(12,2) NOT NULL,
  `shipping_method` varchar(128) NOT NULL,
  `shipping_code` varchar(128) NOT NULL,
  `status` varchar(100) NOT NULL,
  `guest_email` varchar(75) NOT NULL,
  `date_placed` datetime(6) NOT NULL,
  `history_id` int(11) NOT NULL AUTO_INCREMENT,
  `history_date` datetime(6) NOT NULL,
  `history_type` varchar(1) NOT NULL,
  `basket_id` int(11) DEFAULT NULL,
  `billing_address_id` int(11) DEFAULT NULL,
  `history_user_id` int(11) DEFAULT NULL,
  `shipping_address_id` int(11) DEFAULT NULL,
  `site_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`history_id`),
  KEY `order_hist_history_user_id_73541b4be072e484_fk_ecommerce_user_id` (`history_user_id`),
  KEY `order_historicalorder_b80bb774` (`id`),
  KEY `order_historicalorder_b1bc248a` (`number`),
  KEY `order_historicalorder_90e84921` (`date_placed`),
  CONSTRAINT `order_hist_history_user_id_73541b4be072e484_fk_ecommerce_user_id` FOREIGN KEY (`history_user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `order_line`;
CREATE TABLE `order_line` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `partner_name` varchar(128) NOT NULL,
  `partner_sku` varchar(128) NOT NULL,
  `partner_line_reference` varchar(128) NOT NULL,
  `partner_line_notes` longtext NOT NULL,
  `title` varchar(255) NOT NULL,
  `upc` varchar(128) DEFAULT NULL,
  `quantity` int(10) unsigned NOT NULL,
  `line_price_incl_tax` decimal(12,2) NOT NULL,
  `line_price_excl_tax` decimal(12,2) NOT NULL,
  `line_price_before_discounts_incl_tax` decimal(12,2) NOT NULL,
  `line_price_before_discounts_excl_tax` decimal(12,2) NOT NULL,
  `unit_cost_price` decimal(12,2) DEFAULT NULL,
  `unit_price_incl_tax` decimal(12,2) DEFAULT NULL,
  `unit_price_excl_tax` decimal(12,2) DEFAULT NULL,
  `unit_retail_price` decimal(12,2) DEFAULT NULL,
  `status` varchar(255) NOT NULL,
  `est_dispatch_date` date DEFAULT NULL,
  `order_id` int(11) NOT NULL,
  `partner_id` int(11),
  `product_id` int(11),
  `stockrecord_id` int(11),
  PRIMARY KEY (`id`),
  KEY `order_line_69dfcb07` (`order_id`),
  KEY `order_line_4e98b6eb` (`partner_id`),
  KEY `order_line_9bea82de` (`product_id`),
  KEY `order_line_271c5733` (`stockrecord_id`),
  CONSTRAINT `order__stockrecord_id_3d43d2c9d3c4cead_fk_partner_stockrecord_id` FOREIGN KEY (`stockrecord_id`) REFERENCES `partner_stockrecord` (`id`),
  CONSTRAINT `order_line_order_id_419b4779ab1b2c44_fk_order_order_id` FOREIGN KEY (`order_id`) REFERENCES `order_order` (`id`),
  CONSTRAINT `order_line_partner_id_4f32db65ffdc9bc8_fk_partner_partner_id` FOREIGN KEY (`partner_id`) REFERENCES `partner_partner` (`id`),
  CONSTRAINT `order_line_product_id_7ac413b808fdbe0d_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`)
) ;

DROP TABLE IF EXISTS `order_lineattribute`;
CREATE TABLE `order_lineattribute` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(128) NOT NULL,
  `value` varchar(255) NOT NULL,
  `line_id` int(11) NOT NULL,
  `option_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `order_lineattribute_line_id_361105dcc9876c7c_fk_order_line_id` (`line_id`),
  KEY `order_lineattr_option_id_4a223782d95984a5_fk_catalogue_option_id` (`option_id`),
  CONSTRAINT `order_lineattr_option_id_4a223782d95984a5_fk_catalogue_option_id` FOREIGN KEY (`option_id`) REFERENCES `catalogue_option` (`id`),
  CONSTRAINT `order_lineattribute_line_id_361105dcc9876c7c_fk_order_line_id` FOREIGN KEY (`line_id`) REFERENCES `order_line` (`id`)
) ;

DROP TABLE IF EXISTS `order_lineprice`;
CREATE TABLE `order_lineprice` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `quantity` int(10) unsigned NOT NULL,
  `price_incl_tax` decimal(12,2) NOT NULL,
  `price_excl_tax` decimal(12,2) NOT NULL,
  `shipping_incl_tax` decimal(12,2) NOT NULL,
  `shipping_excl_tax` decimal(12,2) NOT NULL,
  `line_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `order_lineprice_line_id_42df16f62bd792af_fk_order_line_id` (`line_id`),
  KEY `order_lineprice_69dfcb07` (`order_id`),
  CONSTRAINT `order_lineprice_line_id_42df16f62bd792af_fk_order_line_id` FOREIGN KEY (`line_id`) REFERENCES `order_line` (`id`),
  CONSTRAINT `order_lineprice_order_id_6a6e2d71fc788284_fk_order_order_id` FOREIGN KEY (`order_id`) REFERENCES `order_order` (`id`)
) ;

DROP TABLE IF EXISTS `order_orderdiscount`;
CREATE TABLE `order_orderdiscount` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category` varchar(64) NOT NULL,
  `offer_id` int(10) unsigned DEFAULT NULL,
  `offer_name` varchar(128) NOT NULL,
  `voucher_id` int(10) unsigned DEFAULT NULL,
  `voucher_code` varchar(128) NOT NULL,
  `frequency` int(10) unsigned DEFAULT NULL,
  `amount` decimal(12,2) NOT NULL,
  `message` longtext NOT NULL,
  `order_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `order_orderdiscount_order_id_74eee63bc9b32980_fk_order_order_id` (`order_id`),
  KEY `order_orderdiscount_9eeed246` (`offer_name`),
  KEY `order_orderdiscount_08e4f7cd` (`voucher_code`),
  CONSTRAINT `order_orderdiscount_order_id_74eee63bc9b32980_fk_order_order_id` FOREIGN KEY (`order_id`) REFERENCES `order_order` (`id`)
) ;

DROP TABLE IF EXISTS `order_ordernote`;
CREATE TABLE `order_ordernote` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `note_type` varchar(128) NOT NULL,
  `message` longtext NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `date_updated` datetime(6) NOT NULL,
  `order_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `order_ordernote_order_id_65637e2418771857_fk_order_order_id` (`order_id`),
  KEY `order_ordernote_user_id_86a59b68ba6447d_fk_ecommerce_user_id` (`user_id`),
  CONSTRAINT `order_ordernote_order_id_65637e2418771857_fk_order_order_id` FOREIGN KEY (`order_id`) REFERENCES `order_order` (`id`),
  CONSTRAINT `order_ordernote_user_id_86a59b68ba6447d_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `order_paymenteventtype`;
CREATE TABLE `order_paymenteventtype` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `code` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `code` (`code`)
) ;

DROP TABLE IF EXISTS `order_shippingeventtype`;
CREATE TABLE `order_shippingeventtype` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `code` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `code` (`code`)
);

LOCK TABLES `order_shippingeventtype` WRITE;
INSERT INTO `order_shippingeventtype` VALUES (1,'Shipped','shipped');
UNLOCK TABLES;

DROP TABLE IF EXISTS `order_shippingevent`;
CREATE TABLE `order_shippingevent` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `notes` longtext NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `event_type_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `order_shippingevent_5e891baf` (`event_type_id`),
  KEY `order_shippingevent_69dfcb07` (`order_id`),
  CONSTRAINT `ord_event_type_id_71e47410f9647141_fk_order_shippingeventtype_id` FOREIGN KEY (`event_type_id`) REFERENCES `order_shippingeventtype` (`id`),
  CONSTRAINT `order_shippingevent_order_id_68b1b0f1be0500e3_fk_order_order_id` FOREIGN KEY (`order_id`) REFERENCES `order_order` (`id`)
) ;

DROP TABLE IF EXISTS `order_paymentevent`;
CREATE TABLE `order_paymentevent` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `amount` decimal(12,2) NOT NULL,
  `reference` varchar(128) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `event_type_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `shipping_event_id` int(11),
  `processor_name` varchar(32),
  PRIMARY KEY (`id`),
  KEY `order_paymentevent_5e891baf` (`event_type_id`),
  KEY `order_paymentevent_69dfcb07` (`order_id`),
  KEY `order_paymentevent_78cafb71` (`shipping_event_id`),
  CONSTRAINT `ord_shipping_event_id_2387ec9d4c55ca00_fk_order_shippingevent_id` FOREIGN KEY (`shipping_event_id`) REFERENCES `order_shippingevent` (`id`),
  CONSTRAINT `orde_event_type_id_30d2e580e1d682f4_fk_order_paymenteventtype_id` FOREIGN KEY (`event_type_id`) REFERENCES `order_paymenteventtype` (`id`),
  CONSTRAINT `order_paymentevent_order_id_42d3803ca07e2418_fk_order_order_id` FOREIGN KEY (`order_id`) REFERENCES `order_order` (`id`)
) ;

DROP TABLE IF EXISTS `order_paymenteventquantity`;
CREATE TABLE `order_paymenteventquantity` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `quantity` int(10) unsigned NOT NULL,
  `event_id` int(11) NOT NULL,
  `line_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `order_paymenteventquantity_event_id_71c85d21cf10e2a9_uniq` (`event_id`,`line_id`),
  KEY `order_paymenteventquan_line_id_2641216f31e00d64_fk_order_line_id` (`line_id`),
  CONSTRAINT `order_paymente_event_id_1fd0b26db2b9e09_fk_order_paymentevent_id` FOREIGN KEY (`event_id`) REFERENCES `order_paymentevent` (`id`),
  CONSTRAINT `order_paymenteventquan_line_id_2641216f31e00d64_fk_order_line_id` FOREIGN KEY (`line_id`) REFERENCES `order_line` (`id`)
) ;

DROP TABLE IF EXISTS `order_shippingeventquantity`;
CREATE TABLE `order_shippingeventquantity` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `quantity` int(10) unsigned NOT NULL,
  `event_id` int(11) NOT NULL,
  `line_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `order_shippingeventquantity_event_id_7d8b3647671b075e_uniq` (`event_id`,`line_id`),
  KEY `order_shippingeventqua_line_id_391505a0fa0abef7_fk_order_line_id` (`line_id`),
  CONSTRAINT `order_shippi_event_id_7765e7fe70caea64_fk_order_shippingevent_id` FOREIGN KEY (`event_id`) REFERENCES `order_shippingevent` (`id`),
  CONSTRAINT `order_shippingeventqua_line_id_391505a0fa0abef7_fk_order_line_id` FOREIGN KEY (`line_id`) REFERENCES `order_line` (`id`)
) ;

DROP TABLE IF EXISTS `partner_historicalstockrecord`;
CREATE TABLE `partner_historicalstockrecord` (
  `id` int(11) NOT NULL,
  `partner_sku` varchar(128) NOT NULL,
  `price_currency` varchar(12) NOT NULL,
  `price_excl_tax` decimal(12,2) DEFAULT NULL,
  `price_retail` decimal(12,2) DEFAULT NULL,
  `cost_price` decimal(12,2) DEFAULT NULL,
  `num_in_stock` int(10) unsigned DEFAULT NULL,
  `num_allocated` int(11) DEFAULT NULL,
  `low_stock_threshold` int(10) unsigned DEFAULT NULL,
  `date_created` datetime(6) NOT NULL,
  `date_updated` datetime(6) NOT NULL,
  `history_id` int(11) NOT NULL AUTO_INCREMENT,
  `history_date` datetime(6) NOT NULL,
  `history_type` varchar(1) NOT NULL,
  `history_user_id` int(11) DEFAULT NULL,
  `partner_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`history_id`),
  KEY `partner_hi_history_user_id_47e781174f2b3f47_fk_ecommerce_user_id` (`history_user_id`),
  KEY `partner_historicalstockrecord_b80bb774` (`id`),
  KEY `partner_historicalstockrecord_9474e4b5` (`date_updated`),
  CONSTRAINT `partner_hi_history_user_id_47e781174f2b3f47_fk_ecommerce_user_id` FOREIGN KEY (`history_user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `partner_partner_users`;
CREATE TABLE `partner_partner_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `partner_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `partner_id` (`partner_id`,`user_id`),
  KEY `partner_partner_us_user_id_216882a7741d5a52_fk_ecommerce_user_id` (`user_id`),
  CONSTRAINT `partner_partne_partner_id_63b121e5c6d97f4a_fk_partner_partner_id` FOREIGN KEY (`partner_id`) REFERENCES `partner_partner` (`id`),
  CONSTRAINT `partner_partner_us_user_id_216882a7741d5a52_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `partner_partneraddress`;
CREATE TABLE `partner_partneraddress` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(64) NOT NULL,
  `first_name` varchar(255) NOT NULL,
  `last_name` varchar(255) NOT NULL,
  `line1` varchar(255) NOT NULL,
  `line2` varchar(255) NOT NULL,
  `line3` varchar(255) NOT NULL,
  `line4` varchar(255) NOT NULL,
  `state` varchar(255) NOT NULL,
  `postcode` varchar(64) NOT NULL,
  `search_text` longtext NOT NULL,
  `country_id` varchar(2) NOT NULL,
  `partner_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `par_country_id_781c73d5cc70eb3e_fk_address_country_iso_3166_1_a2` (`country_id`),
  KEY `partner_partner_partner_id_54787daca128952_fk_partner_partner_id` (`partner_id`),
  CONSTRAINT `par_country_id_781c73d5cc70eb3e_fk_address_country_iso_3166_1_a2` FOREIGN KEY (`country_id`) REFERENCES `address_country` (`iso_3166_1_a2`),
  CONSTRAINT `partner_partner_partner_id_54787daca128952_fk_partner_partner_id` FOREIGN KEY (`partner_id`) REFERENCES `partner_partner` (`id`)
) ;

DROP TABLE IF EXISTS `partner_stockalert`;
CREATE TABLE `partner_stockalert` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `threshold` int(10) unsigned NOT NULL,
  `status` varchar(128) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `date_closed` datetime(6) DEFAULT NULL,
  `stockrecord_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `partner_stockalert_271c5733` (`stockrecord_id`),
  CONSTRAINT `partner_stockrecord_id_c1298620d4e8adb_fk_partner_stockrecord_id` FOREIGN KEY (`stockrecord_id`) REFERENCES `partner_stockrecord` (`id`)
) ;

DROP TABLE IF EXISTS `payment_bankcard`;
CREATE TABLE `payment_bankcard` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `card_type` varchar(128) NOT NULL,
  `name` varchar(255) NOT NULL,
  `number` varchar(32) NOT NULL,
  `expiry_date` date NOT NULL,
  `partner_reference` varchar(255) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `payment_bankcard_user_id_2fbace85ccaf6406_fk_ecommerce_user_id` (`user_id`),
  CONSTRAINT `payment_bankcard_user_id_2fbace85ccaf6406_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `payment_paymentprocessorresponse`;
CREATE TABLE `payment_paymentprocessorresponse` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `processor_name` varchar(255) NOT NULL,
  `transaction_id` varchar(255) DEFAULT NULL,
  `response` longtext NOT NULL,
  `created` datetime(6) NOT NULL,
  `basket_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `payment_paymentprocessorresp_processor_name_44723067fce53254_idx` (`processor_name`,`transaction_id`),
  KEY `payment_paymentpr_basket_id_6e5b6d68eb27c77c_fk_basket_basket_id` (`basket_id`),
  KEY `payment_paymentprocessorresponse_e2fa5388` (`created`),
  CONSTRAINT `payment_paymentpr_basket_id_6e5b6d68eb27c77c_fk_basket_basket_id` FOREIGN KEY (`basket_id`) REFERENCES `basket_basket` (`id`)
) ;

DROP TABLE IF EXISTS `payment_paypalprocessorconfiguration`;
CREATE TABLE `payment_paypalprocessorconfiguration` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `retry_attempts` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ;

DROP TABLE IF EXISTS `payment_paypalwebprofile`;
CREATE TABLE `payment_paypalwebprofile` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ;

DROP TABLE IF EXISTS `payment_sourcetype`;
CREATE TABLE `payment_sourcetype` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `code` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ;

DROP TABLE IF EXISTS `payment_source`;
CREATE TABLE `payment_source` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `currency` varchar(12) NOT NULL,
  `amount_allocated` decimal(12,2) NOT NULL,
  `amount_debited` decimal(12,2) NOT NULL,
  `amount_refunded` decimal(12,2) NOT NULL,
  `reference` varchar(128) NOT NULL,
  `label` varchar(128) NOT NULL,
  `order_id` int(11) NOT NULL,
  `source_type_id` int(11) NOT NULL,
  `card_type` varchar(255),
  PRIMARY KEY (`id`),
  KEY `payment_source_order_id_7b79e8c352550a9f_fk_order_order_id` (`order_id`),
  KEY `payment_source_ed5cb66b` (`source_type_id`),
  CONSTRAINT `payment_source_order_id_7b79e8c352550a9f_fk_order_order_id` FOREIGN KEY (`order_id`) REFERENCES `order_order` (`id`),
  CONSTRAINT `payment_source_type_id_7c2576fef8fe5b73_fk_payment_sourcetype_id` FOREIGN KEY (`source_type_id`) REFERENCES `payment_sourcetype` (`id`)
) ;

DROP TABLE IF EXISTS `payment_transaction`;
CREATE TABLE `payment_transaction` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `txn_type` varchar(128) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `reference` varchar(128) NOT NULL,
  `status` varchar(128) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `source_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `payment_transact_source_id_62a77f3472114bb9_fk_payment_source_id` (`source_id`),
  CONSTRAINT `payment_transact_source_id_62a77f3472114bb9_fk_payment_source_id` FOREIGN KEY (`source_id`) REFERENCES `payment_source` (`id`)
) ;

DROP TABLE IF EXISTS `promotions_automaticproductlist`;
CREATE TABLE `promotions_automaticproductlist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` longtext NOT NULL,
  `link_url` varchar(200) NOT NULL,
  `link_text` varchar(255) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `method` varchar(128) NOT NULL,
  `num_products` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ;

DROP TABLE IF EXISTS `promotions_handpickedproductlist`;
CREATE TABLE `promotions_handpickedproductlist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` longtext NOT NULL,
  `link_url` varchar(200) NOT NULL,
  `link_text` varchar(255) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ;

DROP TABLE IF EXISTS `promotions_image`;
CREATE TABLE `promotions_image` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `link_url` varchar(200) NOT NULL,
  `image` varchar(255) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ;

DROP TABLE IF EXISTS `promotions_keywordpromotion`;
CREATE TABLE `promotions_keywordpromotion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `object_id` int(10) unsigned NOT NULL,
  `position` varchar(100) NOT NULL,
  `display_order` int(10) unsigned NOT NULL,
  `clicks` int(10) unsigned NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `keyword` varchar(200) NOT NULL,
  `filter` varchar(200) NOT NULL,
  `content_type_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `promo_content_type_id_5263f43817f7f542_fk_django_content_type_id` (`content_type_id`),
  CONSTRAINT `promo_content_type_id_5263f43817f7f542_fk_django_content_type_id` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`)
) ;

DROP TABLE IF EXISTS `promotions_multiimage`;
CREATE TABLE `promotions_multiimage` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ;

DROP TABLE IF EXISTS `promotions_multiimage_images`;
CREATE TABLE `promotions_multiimage_images` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `multiimage_id` int(11) NOT NULL,
  `image_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `multiimage_id` (`multiimage_id`,`image_id`),
  KEY `promotions_mult_image_id_43db841908b2f050_fk_promotions_image_id` (`image_id`),
  CONSTRAINT `promo_multiimage_id_5c121d63478f73ce_fk_promotions_multiimage_id` FOREIGN KEY (`multiimage_id`) REFERENCES `promotions_multiimage` (`id`),
  CONSTRAINT `promotions_mult_image_id_43db841908b2f050_fk_promotions_image_id` FOREIGN KEY (`image_id`) REFERENCES `promotions_image` (`id`)
) ;

DROP TABLE IF EXISTS `promotions_orderedproduct`;
CREATE TABLE `promotions_orderedproduct` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `display_order` int(10) unsigned NOT NULL,
  `list_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `promotions_orderedproduct_list_id_37d6675dc717b620_uniq` (`list_id`,`product_id`),
  KEY `promotions_orderedproduct_4da3e820` (`list_id`),
  KEY `promotions_orderedproduct_9bea82de` (`product_id`),
  CONSTRAINT `list_id_444fecc458ce046a_fk_promotions_handpickedproductlist_id` FOREIGN KEY (`list_id`) REFERENCES `promotions_handpickedproductlist` (`id`),
  CONSTRAINT `promotions_or_product_id_cd28624cf774b34_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`)
) ;

DROP TABLE IF EXISTS `promotions_tabbedblock`;
CREATE TABLE `promotions_tabbedblock` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ;

DROP TABLE IF EXISTS `promotions_orderedproductlist`;
CREATE TABLE `promotions_orderedproductlist` (
  `handpickedproductlist_ptr_id` int(11) NOT NULL,
  `display_order` int(10) unsigned NOT NULL,
  `tabbed_block_id` int(11) NOT NULL,
  PRIMARY KEY (`handpickedproductlist_ptr_id`),
  KEY `promotions_orderedproductlist_1f46f425` (`tabbed_block_id`),
  CONSTRAINT `D7dc95a31fc510889dbe6b78d6be9adc` FOREIGN KEY (`handpickedproductlist_ptr_id`) REFERENCES `promotions_handpickedproductlist` (`id`),
  CONSTRAINT `pr_tabbed_block_id_161cbac03ca7677a_fk_promotions_tabbedblock_id` FOREIGN KEY (`tabbed_block_id`) REFERENCES `promotions_tabbedblock` (`id`)
) ;

DROP TABLE IF EXISTS `promotions_pagepromotion`;
CREATE TABLE `promotions_pagepromotion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `object_id` int(10) unsigned NOT NULL,
  `position` varchar(100) NOT NULL,
  `display_order` int(10) unsigned NOT NULL,
  `clicks` int(10) unsigned NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `page_url` varchar(128) NOT NULL,
  `content_type_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `promot_content_type_id_543b3d3d3af6caf_fk_django_content_type_id` (`content_type_id`),
  KEY `promotions_pagepromotion_072c6e88` (`page_url`),
  CONSTRAINT `promot_content_type_id_543b3d3d3af6caf_fk_django_content_type_id` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`)
) ;

DROP TABLE IF EXISTS `promotions_rawhtml`;
CREATE TABLE `promotions_rawhtml` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `display_type` varchar(128) NOT NULL,
  `body` longtext NOT NULL,
  `date_created` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ;

DROP TABLE IF EXISTS `promotions_singleproduct`;
CREATE TABLE `promotions_singleproduct` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `description` longtext NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `product_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `promotions_s_product_id_7ecad2f2be6785d6_fk_catalogue_product_id` (`product_id`),
  CONSTRAINT `promotions_s_product_id_7ecad2f2be6785d6_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`)
) ;

DROP TABLE IF EXISTS `referrals_referral`;
CREATE TABLE `referrals_referral` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  `affiliate_id` varchar(255) NOT NULL,
  `basket_id` int(11) DEFAULT NULL,
  `order_id` int(11) DEFAULT NULL,
  `site_id` int(11),
  `utm_campaign` varchar(255) NOT NULL,
  `utm_content` varchar(255) NOT NULL,
  `utm_created_at` datetime(6) DEFAULT NULL,
  `utm_medium` varchar(255) NOT NULL,
  `utm_source` varchar(255) NOT NULL,
  `utm_term` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `basket_id` (`basket_id`),
  UNIQUE KEY `order_id` (`order_id`),
  KEY `referrals_referral_9365d6e7` (`site_id`),
  CONSTRAINT `referrals_referra_basket_id_3781d55b7e02a9c6_fk_basket_basket_id` FOREIGN KEY (`basket_id`) REFERENCES `basket_basket` (`id`),
  CONSTRAINT `referrals_referral_order_id_6361145afb459d2b_fk_order_order_id` FOREIGN KEY (`order_id`) REFERENCES `order_order` (`id`),
  CONSTRAINT `referrals_referral_site_id_3f736591500924a1_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`)
) ;

DROP TABLE IF EXISTS `refund_historicalrefund`;
CREATE TABLE `refund_historicalrefund` (
  `id` int(11) NOT NULL,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  `total_credit_excl_tax` decimal(12,2) NOT NULL,
  `currency` varchar(12) NOT NULL,
  `status` varchar(255) NOT NULL,
  `history_id` int(11) NOT NULL AUTO_INCREMENT,
  `history_date` datetime(6) NOT NULL,
  `history_type` varchar(1) NOT NULL,
  `history_user_id` int(11) DEFAULT NULL,
  `order_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`history_id`),
  KEY `refund_his_history_user_id_6ddb440a6c4150cc_fk_ecommerce_user_id` (`history_user_id`),
  KEY `refund_historicalrefund_b80bb774` (`id`),
  CONSTRAINT `refund_his_history_user_id_6ddb440a6c4150cc_fk_ecommerce_user_id` FOREIGN KEY (`history_user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `refund_historicalrefundline`;
CREATE TABLE `refund_historicalrefundline` (
  `id` int(11) NOT NULL,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  `line_credit_excl_tax` decimal(12,2) NOT NULL,
  `quantity` int(10) unsigned NOT NULL,
  `status` varchar(255) NOT NULL,
  `history_id` int(11) NOT NULL AUTO_INCREMENT,
  `history_date` datetime(6) NOT NULL,
  `history_type` varchar(1) NOT NULL,
  `history_user_id` int(11) DEFAULT NULL,
  `order_line_id` int(11) DEFAULT NULL,
  `refund_id` int(11),
  PRIMARY KEY (`history_id`),
  KEY `refund_hist_history_user_id_4483f4185837402_fk_ecommerce_user_id` (`history_user_id`),
  KEY `refund_historicalrefundline_b80bb774` (`id`),
  KEY `refund_historicalrefundline_cd7a5ec5` (`refund_id`),
  CONSTRAINT `refund_hist_history_user_id_4483f4185837402_fk_ecommerce_user_id` FOREIGN KEY (`history_user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `refund_refund`;
CREATE TABLE `refund_refund` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  `total_credit_excl_tax` decimal(12,2) NOT NULL,
  `currency` varchar(12) NOT NULL,
  `status` varchar(255) NOT NULL,
  `order_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `refund_refund_order_id_53ede17610312a47_fk_order_order_id` (`order_id`),
  KEY `refund_refund_user_id_707067ea382e6df3_fk_ecommerce_user_id` (`user_id`),
  CONSTRAINT `refund_refund_order_id_53ede17610312a47_fk_order_order_id` FOREIGN KEY (`order_id`) REFERENCES `order_order` (`id`),
  CONSTRAINT `refund_refund_user_id_707067ea382e6df3_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `refund_refundline`;
CREATE TABLE `refund_refundline` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  `line_credit_excl_tax` decimal(12,2) NOT NULL,
  `quantity` int(10) unsigned NOT NULL,
  `status` varchar(255) NOT NULL,
  `order_line_id` int(11) NOT NULL,
  `refund_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `refund_refundlin_order_line_id_6424676f12f22271_fk_order_line_id` (`order_line_id`),
  KEY `refund_refundline_refund_id_de28863d9bde7ae_fk_refund_refund_id` (`refund_id`),
  CONSTRAINT `refund_refundlin_order_line_id_6424676f12f22271_fk_order_line_id` FOREIGN KEY (`order_line_id`) REFERENCES `order_line` (`id`),
  CONSTRAINT `refund_refundline_refund_id_de28863d9bde7ae_fk_refund_refund_id` FOREIGN KEY (`refund_id`) REFERENCES `refund_refund` (`id`)
) ;

DROP TABLE IF EXISTS `reviews_productreview`;
CREATE TABLE `reviews_productreview` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `score` smallint(6) NOT NULL,
  `title` varchar(255) NOT NULL,
  `body` longtext NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(75) NOT NULL,
  `homepage` varchar(200) NOT NULL,
  `status` smallint(6) NOT NULL,
  `total_votes` int(11) NOT NULL,
  `delta_votes` int(11) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `product_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `reviews_productreview_product_id_2dbdd3287f68dc33_uniq` (`product_id`,`user_id`),
  KEY `reviews_productrev_user_id_706f739ddcd1e789_fk_ecommerce_user_id` (`user_id`),
  KEY `reviews_productreview_979acfd1` (`delta_votes`),
  CONSTRAINT `reviews_prod_product_id_3d87cf5f0f9d099a_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`),
  CONSTRAINT `reviews_productrev_user_id_706f739ddcd1e789_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `reviews_vote`;
CREATE TABLE `reviews_vote` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `delta` smallint(6) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `review_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `reviews_vote_user_id_75acca213178559b_uniq` (`user_id`,`review_id`),
  KEY `reviews_vo_review_id_2924a65bdf9b082_fk_reviews_productreview_id` (`review_id`),
  CONSTRAINT `reviews_vo_review_id_2924a65bdf9b082_fk_reviews_productreview_id` FOREIGN KEY (`review_id`) REFERENCES `reviews_productreview` (`id`),
  CONSTRAINT `reviews_vote_user_id_67d2dce94046a805_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `shipping_orderanditemcharges`;
CREATE TABLE `shipping_orderanditemcharges` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(128) NOT NULL,
  `name` varchar(128) NOT NULL,
  `description` longtext NOT NULL,
  `price_per_order` decimal(12,2) NOT NULL,
  `price_per_item` decimal(12,2) NOT NULL,
  `free_shipping_threshold` decimal(12,2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  UNIQUE KEY `name` (`name`)
) ;

DROP TABLE IF EXISTS `shipping_orderanditemcharges_countries`;
CREATE TABLE `shipping_orderanditemcharges_countries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orderanditemcharges_id` int(11) NOT NULL,
  `country_id` varchar(2) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `orderanditemcharges_id` (`orderanditemcharges_id`,`country_id`),
  KEY `shi_country_id_6427960716333ddc_fk_address_country_iso_3166_1_a2` (`country_id`),
  CONSTRAINT `D4781fcfcea3dae82b272c91a62b305e` FOREIGN KEY (`orderanditemcharges_id`) REFERENCES `shipping_orderanditemcharges` (`id`),
  CONSTRAINT `shi_country_id_6427960716333ddc_fk_address_country_iso_3166_1_a2` FOREIGN KEY (`country_id`) REFERENCES `address_country` (`iso_3166_1_a2`)
) ;

DROP TABLE IF EXISTS `shipping_weightbased`;
CREATE TABLE `shipping_weightbased` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(128) NOT NULL,
  `name` varchar(128) NOT NULL,
  `description` longtext NOT NULL,
  `default_weight` decimal(12,3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  UNIQUE KEY `name` (`name`)
) ;

DROP TABLE IF EXISTS `shipping_weightband`;
CREATE TABLE `shipping_weightband` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `upper_limit` decimal(12,3) NOT NULL,
  `charge` decimal(12,2) NOT NULL,
  `method_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `shipping_weightband_836f12fb` (`method_id`),
  CONSTRAINT `shipping_w_method_id_4ad1280fd58ce538_fk_shipping_weightbased_id` FOREIGN KEY (`method_id`) REFERENCES `shipping_weightbased` (`id`)
) ;

DROP TABLE IF EXISTS `shipping_weightbased_countries`;
CREATE TABLE `shipping_weightbased_countries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `weightbased_id` int(11) NOT NULL,
  `country_id` varchar(2) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `weightbased_id` (`weightbased_id`,`country_id`),
  KEY `shi_country_id_357014e9a25eac38_fk_address_country_iso_3166_1_a2` (`country_id`),
  CONSTRAINT `shi_country_id_357014e9a25eac38_fk_address_country_iso_3166_1_a2` FOREIGN KEY (`country_id`) REFERENCES `address_country` (`iso_3166_1_a2`),
  CONSTRAINT `shipp_weightbased_id_584cd63ef43d6c55_fk_shipping_weightbased_id` FOREIGN KEY (`weightbased_id`) REFERENCES `shipping_weightbased` (`id`)
) ;

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
) ;

DROP TABLE IF EXISTS `social_auth_code`;
CREATE TABLE `social_auth_code` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(254) NOT NULL,
  `code` varchar(32) NOT NULL,
  `verified` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `social_auth_code_email_75f27066d057e3b6_uniq` (`email`,`code`),
  KEY `social_auth_code_c1336794` (`code`)
) ;

DROP TABLE IF EXISTS `social_auth_nonce`;
CREATE TABLE `social_auth_nonce` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_url` varchar(255) NOT NULL,
  `timestamp` int(11) NOT NULL,
  `salt` varchar(65) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `social_auth_nonce_server_url_36601f978463b4_uniq` (`server_url`,`timestamp`,`salt`)
) ;

DROP TABLE IF EXISTS `social_auth_usersocialauth`;
CREATE TABLE `social_auth_usersocialauth` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `provider` varchar(32) NOT NULL,
  `uid` varchar(255) NOT NULL,
  `extra_data` longtext NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `social_auth_usersocialauth_provider_2f763109e2c4a1fb_uniq` (`provider`,`uid`),
  KEY `social_auth_userso_user_id_193b2d80880502b2_fk_ecommerce_user_id` (`user_id`),
  CONSTRAINT `social_auth_userso_user_id_193b2d80880502b2_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `theming_sitetheme`;
CREATE TABLE `theming_sitetheme` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `theme_dir_name` varchar(255) NOT NULL,
  `site_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `theming_sitetheme_site_id_4fccdacaebfeb01f_fk_django_site_id` (`site_id`),
  CONSTRAINT `theming_sitetheme_site_id_4fccdacaebfeb01f_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`)
) ;

DROP TABLE IF EXISTS `thumbnail_kvstore`;
CREATE TABLE `thumbnail_kvstore` (
  `key` varchar(200) NOT NULL,
  `value` longtext NOT NULL,
  PRIMARY KEY (`key`)
) ;

DROP TABLE IF EXISTS `voucher_couponvouchers`;
CREATE TABLE `voucher_couponvouchers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `coupon_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `voucher_coupo_coupon_id_6389ceff3982ad06_fk_catalogue_product_id` (`coupon_id`),
  CONSTRAINT `voucher_coupo_coupon_id_6389ceff3982ad06_fk_catalogue_product_id` FOREIGN KEY (`coupon_id`) REFERENCES `catalogue_product` (`id`)
) ;

DROP TABLE IF EXISTS `voucher_couponvouchers_vouchers`;
CREATE TABLE `voucher_couponvouchers_vouchers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `couponvouchers_id` int(11) NOT NULL,
  `voucher_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `couponvouchers_id` (`couponvouchers_id`,`voucher_id`),
  KEY `voucher_coupon_voucher_id_5db29962b448e2b0_fk_voucher_voucher_id` (`voucher_id`),
  CONSTRAINT `v_couponvouchers_id_ebda79a16ce0af8_fk_voucher_couponvouchers_id` FOREIGN KEY (`couponvouchers_id`) REFERENCES `voucher_couponvouchers` (`id`),
  CONSTRAINT `voucher_coupon_voucher_id_5db29962b448e2b0_fk_voucher_voucher_id` FOREIGN KEY (`voucher_id`) REFERENCES `voucher_voucher` (`id`)
) ;

DROP TABLE IF EXISTS `voucher_orderlinevouchers`;
CREATE TABLE `voucher_orderlinevouchers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `line_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `voucher_orderlinevouch_line_id_400342ab34feafaf_fk_order_line_id` (`line_id`),
  CONSTRAINT `voucher_orderlinevouch_line_id_400342ab34feafaf_fk_order_line_id` FOREIGN KEY (`line_id`) REFERENCES `order_line` (`id`)
) ;

DROP TABLE IF EXISTS `voucher_orderlinevouchers_vouchers`;
CREATE TABLE `voucher_orderlinevouchers_vouchers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orderlinevouchers_id` int(11) NOT NULL,
  `voucher_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `orderlinevouchers_id` (`orderlinevouchers_id`,`voucher_id`),
  KEY `voucher_orderl_voucher_id_2e1249d662a019e9_fk_voucher_voucher_id` (`voucher_id`),
  CONSTRAINT `bd5611e69c881bcc95b6e4e650d152cd` FOREIGN KEY (`orderlinevouchers_id`) REFERENCES `voucher_orderlinevouchers` (`id`),
  CONSTRAINT `voucher_orderl_voucher_id_2e1249d662a019e9_fk_voucher_voucher_id` FOREIGN KEY (`voucher_id`) REFERENCES `voucher_voucher` (`id`)
) ;

DROP TABLE IF EXISTS `voucher_voucher_offers`;
CREATE TABLE `voucher_voucher_offers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `voucher_id` int(11) NOT NULL,
  `conditionaloffer_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `voucher_id` (`voucher_id`,`conditionaloffer_id`),
  KEY `f0962885ad9ea319b17d8a3ab65b1bc0` (`conditionaloffer_id`),
  CONSTRAINT `f0962885ad9ea319b17d8a3ab65b1bc0` FOREIGN KEY (`conditionaloffer_id`) REFERENCES `offer_conditionaloffer` (`id`),
  CONSTRAINT `voucher_vouche_voucher_id_18996085b5c7192c_fk_voucher_voucher_id` FOREIGN KEY (`voucher_id`) REFERENCES `voucher_voucher` (`id`)
) ;

DROP TABLE IF EXISTS `voucher_voucherapplication`;
CREATE TABLE `voucher_voucherapplication` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date_created` date NOT NULL,
  `order_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `voucher_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `voucher_voucherappli_order_id_5dcb3ce35f8e76d0_fk_order_order_id` (`order_id`),
  KEY `voucher_voucherapp_user_id_6ab9212ced39aaa4_fk_ecommerce_user_id` (`user_id`),
  KEY `voucher_vouche_voucher_id_298aa75cf02a99a0_fk_voucher_voucher_id` (`voucher_id`),
  CONSTRAINT `voucher_vouche_voucher_id_298aa75cf02a99a0_fk_voucher_voucher_id` FOREIGN KEY (`voucher_id`) REFERENCES `voucher_voucher` (`id`),
  CONSTRAINT `voucher_voucherapp_user_id_6ab9212ced39aaa4_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`),
  CONSTRAINT `voucher_voucherappli_order_id_5dcb3ce35f8e76d0_fk_order_order_id` FOREIGN KEY (`order_id`) REFERENCES `order_order` (`id`)
) ;

DROP TABLE IF EXISTS `waffle_flag`;
CREATE TABLE `waffle_flag` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `everyone` tinyint(1) DEFAULT NULL,
  `percent` decimal(3,1) DEFAULT NULL,
  `testing` tinyint(1) NOT NULL,
  `superusers` tinyint(1) NOT NULL,
  `staff` tinyint(1) NOT NULL,
  `authenticated` tinyint(1) NOT NULL,
  `languages` longtext NOT NULL,
  `rollout` tinyint(1) NOT NULL,
  `note` longtext NOT NULL,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `waffle_flag_e2fa5388` (`created`)
);


LOCK TABLES `waffle_flag` WRITE;
INSERT INTO `waffle_flag` VALUES (1,'enable_client_side_checkout',NULL,NULL,0,1,0,0,'',0,'This flag determines if the integrated/client-side checkout flow should be enabled.','2017-03-01 23:30:51.755540','2017-03-01 23:30:51.755552');
UNLOCK TABLES;

DROP TABLE IF EXISTS `waffle_flag_groups`;
CREATE TABLE `waffle_flag_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `flag_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `flag_id` (`flag_id`,`group_id`),
  KEY `waffle_flag_groups_group_id_1d214ce64ae3698d_fk_auth_group_id` (`group_id`),
  CONSTRAINT `waffle_flag_groups_flag_id_3d040eff1615da33_fk_waffle_flag_id` FOREIGN KEY (`flag_id`) REFERENCES `waffle_flag` (`id`),
  CONSTRAINT `waffle_flag_groups_group_id_1d214ce64ae3698d_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`)
) ;

DROP TABLE IF EXISTS `waffle_flag_users`;
CREATE TABLE `waffle_flag_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `flag_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `flag_id` (`flag_id`,`user_id`),
  KEY `waffle_flag_users_user_id_3c8ba20de859cb5_fk_ecommerce_user_id` (`user_id`),
  CONSTRAINT `waffle_flag_users_flag_id_fe9e88f3072acde_fk_waffle_flag_id` FOREIGN KEY (`flag_id`) REFERENCES `waffle_flag` (`id`),
  CONSTRAINT `waffle_flag_users_user_id_3c8ba20de859cb5_fk_ecommerce_user_id` FOREIGN KEY (`user_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `waffle_sample`;
CREATE TABLE `waffle_sample` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `percent` decimal(4,1) NOT NULL,
  `note` longtext NOT NULL,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `waffle_sample_e2fa5388` (`created`)
);


LOCK TABLES `waffle_sample` WRITE;
INSERT INTO `waffle_sample` VALUES (1,'async_order_fulfillment',0.0,'Determines what percentage of orders are fulfilled asynchronously.','2017-03-01 23:29:59.431757','2017-03-01 23:29:59.431772');
UNLOCK TABLES;

DROP TABLE IF EXISTS `waffle_switch`;
CREATE TABLE `waffle_switch` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `active` tinyint(1) NOT NULL,
  `note` longtext NOT NULL,
  `created` datetime(6) NOT NULL,
  `modified` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `waffle_switch_e2fa5388` (`created`)
);

LOCK TABLES `waffle_switch` WRITE;
INSERT INTO `waffle_switch` VALUES (1,'publish_course_modes_to_lms',1,'','2017-03-01 23:29:58.161306','2017-03-01 23:29:58.161319'),(3,'create_enrollment_codes',0,'','2017-03-01 23:30:00.849606','2017-03-01 23:30:00.849619'),(4,'payment_processor_active_cybersource',1,'','2017-03-01 23:30:50.976978','2017-03-01 23:30:50.976993'),(5,'payment_processor_active_paypal',1,'','2017-03-01 23:30:50.977921','2017-03-01 23:30:50.977931'),(6,'sailthru_enable',0,'','2017-03-01 23:31:23.525033','2017-03-01 23:31:23.525045');
UNLOCK TABLES;

DROP TABLE IF EXISTS `wishlists_wishlist`;
CREATE TABLE `wishlists_wishlist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `key` varchar(6) NOT NULL,
  `visibility` varchar(20) NOT NULL,
  `date_created` datetime(6) NOT NULL,
  `owner_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `key` (`key`),
  KEY `wishlists_wishlis_owner_id_3033ec0075490f56_fk_ecommerce_user_id` (`owner_id`),
  CONSTRAINT `wishlists_wishlis_owner_id_3033ec0075490f56_fk_ecommerce_user_id` FOREIGN KEY (`owner_id`) REFERENCES `ecommerce_user` (`id`)
) ;

DROP TABLE IF EXISTS `wishlists_line`;
CREATE TABLE `wishlists_line` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `quantity` int(10) unsigned NOT NULL,
  `title` varchar(255) NOT NULL,
  `product_id` int(11) DEFAULT NULL,
  `wishlist_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `wishlists_line_wishlist_id_53bbce7b453dfacc_uniq` (`wishlist_id`,`product_id`),
  KEY `wishlists_li_product_id_470a9463fc5f5b83_fk_catalogue_product_id` (`product_id`),
  KEY `wishlists_line_e2f8e270` (`wishlist_id`),
  CONSTRAINT `wishlists__wishlist_id_6632a3c6e1ec8370_fk_wishlists_wishlist_id` FOREIGN KEY (`wishlist_id`) REFERENCES `wishlists_wishlist` (`id`),
  CONSTRAINT `wishlists_li_product_id_470a9463fc5f5b83_fk_catalogue_product_id` FOREIGN KEY (`product_id`) REFERENCES `catalogue_product` (`id`)
) ;
COMMIT;



