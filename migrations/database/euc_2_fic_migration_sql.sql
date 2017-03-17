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

