/*============api_admin	0001=============================*/
BEGIN;
CREATE TABLE `api_admin_apiaccessrequest` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `status` varchar(255) NOT NULL, `website` varchar(200) NOT NULL, `reason` longtext NOT NULL, `user_id` integer NOT NULL);
CREATE TABLE `api_admin_historicalapiaccessrequest` (`id` integer NOT NULL, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `status` varchar(255) NOT NULL, `website` varchar(200) NOT NULL, `reason` longtext NOT NULL, `history_id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `history_date` datetime(6) NOT NULL, `history_type` varchar(1) NOT NULL, `history_user_id` integer NULL, `user_id` integer NULL);
ALTER TABLE `api_admin_apiaccessrequest` ADD CONSTRAINT `api_admin_apiaccessrequ_user_id_6753e50e296cabc7_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);
CREATE INDEX `api_admin_apiaccessrequest_9acb4454` ON `api_admin_apiaccessrequest` (`status`);
ALTER TABLE `api_admin_historicalapiaccessrequest` ADD CONSTRAINT `api_admin_histo_history_user_id_73c59297a81bcd02_fk_auth_user_id` FOREIGN KEY (`history_user_id`) REFERENCES `auth_user` (`id`);
CREATE INDEX `api_admin_historicalapiaccessrequest_b80bb774` ON `api_admin_historicalapiaccessrequest` (`id`);
CREATE INDEX `api_admin_historicalapiaccessrequest_9acb4454` ON `api_admin_historicalapiaccessrequest` (`status`);

COMMIT;
/*============api_admin	0002=============================*/
BEGIN;
--
-- MIGRATION NOW PERFORMS OPERATION THAT CANNOT BE WRITTEN AS SQL:
-- Raw Python operation
--

COMMIT;
/*============api_admin	0003=============================*/
BEGIN;
CREATE TABLE `api_admin_apiaccessconfig` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `api_admin_apiaccessrequest` ADD COLUMN `company_address` varchar(255) DEFAULT '' NOT NULL;
ALTER TABLE `api_admin_apiaccessrequest` ALTER COLUMN `company_address` DROP DEFAULT;
ALTER TABLE `api_admin_apiaccessrequest` ADD COLUMN `company_name` varchar(255) DEFAULT '' NOT NULL;
ALTER TABLE `api_admin_apiaccessrequest` ALTER COLUMN `company_name` DROP DEFAULT;
ALTER TABLE `api_admin_historicalapiaccessrequest` ADD COLUMN `company_address` varchar(255) DEFAULT '' NOT NULL;
ALTER TABLE `api_admin_historicalapiaccessrequest` ALTER COLUMN `company_address` DROP DEFAULT;
ALTER TABLE `api_admin_historicalapiaccessrequest` ADD COLUMN `company_name` varchar(255) DEFAULT '' NOT NULL;
ALTER TABLE `api_admin_historicalapiaccessrequest` ALTER COLUMN `company_name` DROP DEFAULT;
ALTER TABLE `api_admin_apiaccessrequest` DROP FOREIGN KEY `api_admin_apiaccessrequ_user_id_6753e50e296cabc7_fk_auth_user_id`;
ALTER TABLE `api_admin_apiaccessrequest` ADD CONSTRAINT `api_admin_apiaccessrequest_user_id_6753e50e296cabc7_uniq` UNIQUE (`user_id`);
ALTER TABLE `api_admin_apiaccessrequest` ADD CONSTRAINT `api_admin_apiaccessrequ_user_id_6753e50e296cabc7_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);
ALTER TABLE `api_admin_apiaccessconfig` ADD CONSTRAINT `api_admin_apiacce_changed_by_id_771a504ee92a076c_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============api_admin	0004=============================*/
BEGIN;
ALTER TABLE `api_admin_apiaccessrequest` ADD COLUMN `contacted` bool DEFAULT 0 NOT NULL;
ALTER TABLE `api_admin_apiaccessrequest` ALTER COLUMN `contacted` DROP DEFAULT;
ALTER TABLE `api_admin_apiaccessrequest` ADD COLUMN `site_id` integer DEFAULT 1 NOT NULL;
ALTER TABLE `api_admin_apiaccessrequest` ALTER COLUMN `site_id` DROP DEFAULT;
ALTER TABLE `api_admin_historicalapiaccessrequest` ADD COLUMN `contacted` bool DEFAULT 0 NOT NULL;
ALTER TABLE `api_admin_historicalapiaccessrequest` ALTER COLUMN `contacted` DROP DEFAULT;
ALTER TABLE `api_admin_historicalapiaccessrequest` ADD COLUMN `site_id` integer NULL;
ALTER TABLE `api_admin_historicalapiaccessrequest` ALTER COLUMN `site_id` DROP DEFAULT;
CREATE INDEX `api_admin_apiaccessrequest_9365d6e7` ON `api_admin_apiaccessrequest` (`site_id`);
ALTER TABLE `api_admin_apiaccessrequest` ADD CONSTRAINT `api_admin_apiaccessre_site_id_7963330a765f8041_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`);
CREATE INDEX `api_admin_historicalapiaccessrequest_9365d6e7` ON `api_admin_historicalapiaccessrequest` (`site_id`);

COMMIT;
/*============api_admin	0005=============================*/
BEGIN;
ALTER TABLE `api_admin_apiaccessrequest` DROP FOREIGN KEY `api_admin_apiaccessrequ_user_id_6753e50e296cabc7_fk_auth_user_id`;
ALTER TABLE `api_admin_apiaccessrequest` ADD CONSTRAINT `api_admin_apiaccessrequ_user_id_6753e50e296cabc7_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============api_admin	0006=============================*/
/*============assessment	0002=============================*/
BEGIN;
CREATE TABLE `assessment_staffworkflow` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `scorer_id` varchar(40) NOT NULL, `course_id` varchar(40) NOT NULL, `item_id` varchar(128) NOT NULL, `submission_uuid` varchar(128) NOT NULL UNIQUE, `created_at` datetime(6) NOT NULL, `grading_completed_at` datetime(6) NULL, `grading_started_at` datetime(6) NULL, `cancelled_at` datetime(6) NULL, `assessment` varchar(128) NULL);
CREATE INDEX `assessment_staffworkflow_7b0042c0` ON `assessment_staffworkflow` (`scorer_id`);
CREATE INDEX `assessment_staffworkflow_ea134da7` ON `assessment_staffworkflow` (`course_id`);
CREATE INDEX `assessment_staffworkflow_82bfda79` ON `assessment_staffworkflow` (`item_id`);
CREATE INDEX `assessment_staffworkflow_fde81f11` ON `assessment_staffworkflow` (`created_at`);
CREATE INDEX `assessment_staffworkflow_85d183d8` ON `assessment_staffworkflow` (`grading_completed_at`);
CREATE INDEX `assessment_staffworkflow_0af9deae` ON `assessment_staffworkflow` (`grading_started_at`);
CREATE INDEX `assessment_staffworkflow_740da1db` ON `assessment_staffworkflow` (`cancelled_at`);
CREATE INDEX `assessment_staffworkflow_5096c410` ON `assessment_staffworkflow` (`assessment`);

COMMIT;
/*============certificates	0006=============================*/
BEGIN;
ALTER TABLE `certificates_certificatetemplateasset` ADD COLUMN `asset_slug` varchar(255) NULL UNIQUE;
ALTER TABLE `certificates_certificatetemplateasset` ALTER COLUMN `asset_slug` DROP DEFAULT;

COMMIT;
/*============certificates	0007=============================*/
BEGIN;
CREATE TABLE `certificates_certificateinvalidation` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `notes` longtext NULL, `active` bool NOT NULL, `generated_certificate_id` integer NOT NULL, `invalidated_by_id` integer NOT NULL);
ALTER TABLE `certificates_certificateinvalidation` ADD CONSTRAINT `fa0dc816ca8028cd93e5f2289d405d87` FOREIGN KEY (`generated_certificate_id`) REFERENCES `certificates_generatedcertificate` (`id`);
ALTER TABLE `certificates_certificateinvalidation` ADD CONSTRAINT `certificates__invalidated_by_id_5198db337fb56b7b_fk_auth_user_id` FOREIGN KEY (`invalidated_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============badges	0001=============================*/
BEGIN;
CREATE TABLE `badges_badgeassertion` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `data` longtext NOT NULL, `backend` varchar(50) NOT NULL, `image_url` varchar(200) NOT NULL, `assertion_url` varchar(200) NOT NULL, `modified` datetime(6) NOT NULL, `created` datetime(6) NOT NULL);
CREATE TABLE `badges_badgeclass` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `slug` varchar(255) NOT NULL, `issuing_component` varchar(50) NOT NULL, `display_name` varchar(255) NOT NULL, `course_id` varchar(255) NOT NULL, `description` longtext NOT NULL, `criteria` longtext NOT NULL, `mode` varchar(100) NOT NULL, `image` varchar(100) NOT NULL);
CREATE TABLE `badges_coursecompleteimageconfiguration` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `mode` varchar(125) NOT NULL UNIQUE, `icon` varchar(100) NOT NULL, `default` bool NOT NULL);
ALTER TABLE `badges_badgeclass` ADD CONSTRAINT `badges_badgeclass_slug_7fe9eac3bca91f16_uniq` UNIQUE (`slug`, `issuing_component`, `course_id`);
ALTER TABLE `badges_badgeassertion` ADD COLUMN `badge_class_id` integer NOT NULL;
ALTER TABLE `badges_badgeassertion` ALTER COLUMN `badge_class_id` DROP DEFAULT;
ALTER TABLE `badges_badgeassertion` ADD COLUMN `user_id` integer NOT NULL;
ALTER TABLE `badges_badgeassertion` ALTER COLUMN `user_id` DROP DEFAULT;
CREATE INDEX `badges_badgeassertion_e2fa5388` ON `badges_badgeassertion` (`created`);
CREATE INDEX `badges_badgeclass_2dbcba41` ON `badges_badgeclass` (`slug`);
CREATE INDEX `badges_badgeclass_a57403f2` ON `badges_badgeclass` (`issuing_component`);
CREATE INDEX `badges_badgeassertion_c389e456` ON `badges_badgeassertion` (`badge_class_id`);
ALTER TABLE `badges_badgeassertion` ADD CONSTRAINT `badges_b_badge_class_id_3a4a16cb833201e8_fk_badges_badgeclass_id` FOREIGN KEY (`badge_class_id`) REFERENCES `badges_badgeclass` (`id`);
CREATE INDEX `badges_badgeassertion_e8701ad4` ON `badges_badgeassertion` (`user_id`);
ALTER TABLE `badges_badgeassertion` ADD CONSTRAINT `badges_badgeassertion_user_id_14233cdefee1055a_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============badges	0002=============================*/
BEGIN;
--
-- MIGRATION NOW PERFORMS OPERATION THAT CANNOT BE WRITTEN AS SQL:
-- Raw Python operation
--

COMMIT;
/*============badges	0003=============================*/
BEGIN;
CREATE TABLE `badges_courseeventbadgesconfiguration` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `courses_completed` longtext NOT NULL, `courses_enrolled` longtext NOT NULL, `course_groups` longtext NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `badges_courseeventbadgesconfiguration` ADD CONSTRAINT `badges_courseeven_changed_by_id_50986a94d73238b9_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============bookmarks	0001=============================*/
BEGIN;
CREATE TABLE `bookmarks_bookmark` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `course_key` varchar(255) NOT NULL, `usage_key` varchar(255) NOT NULL, `path` longtext NOT NULL, `user_id` integer NOT NULL);
CREATE TABLE `bookmarks_xblockcache` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `course_key` varchar(255) NOT NULL, `usage_key` varchar(255) NOT NULL UNIQUE, `display_name` varchar(255) NOT NULL, `paths` longtext NOT NULL);
ALTER TABLE `bookmarks_bookmark` ADD COLUMN `xblock_cache_id` integer NOT NULL;
ALTER TABLE `bookmarks_bookmark` ALTER COLUMN `xblock_cache_id` DROP DEFAULT;
ALTER TABLE `bookmarks_bookmark` ADD CONSTRAINT `bookmarks_bookmark_user_id_7059f67cddd52c9a_uniq` UNIQUE (`user_id`, `usage_key`);
ALTER TABLE `bookmarks_bookmark` ADD CONSTRAINT `bookmarks_bookmark_user_id_33914fa9accf01cb_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);
CREATE INDEX `bookmarks_bookmark_c8235886` ON `bookmarks_bookmark` (`course_key`);
CREATE INDEX `bookmarks_bookmark_4a93f0de` ON `bookmarks_bookmark` (`usage_key`);
CREATE INDEX `bookmarks_xblockcache_c8235886` ON `bookmarks_xblockcache` (`course_key`);
CREATE INDEX `bookmarks_bookmark_d452fbf6` ON `bookmarks_bookmark` (`xblock_cache_id`);
ALTER TABLE `bookmarks_bookmark` ADD CONSTRAINT `boo_xblock_cache_id_22d48842487ba2d2_fk_bookmarks_xblockcache_id` FOREIGN KEY (`xblock_cache_id`) REFERENCES `bookmarks_xblockcache` (`id`);

COMMIT;
/*============bulk_email	0003=============================*/
BEGIN;
CREATE TABLE `bulk_email_bulkemailflag` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `require_course_email_auth` bool NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `bulk_email_bulkemailflag` ADD CONSTRAINT `bulk_email_bulkem_changed_by_id_67960d6511f876aa_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============bulk_email	0004=============================*/
BEGIN;
CREATE TABLE `bulk_email_target` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `target_type` varchar(64) NOT NULL);
CREATE TABLE `bulk_email_cohorttarget` (`target_ptr_id` integer NOT NULL PRIMARY KEY, `cohort_id` integer NOT NULL);
CREATE TABLE `bulk_email_courseemail_targets` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `courseemail_id` integer NOT NULL, `target_id` integer NOT NULL, UNIQUE (`courseemail_id`, `target_id`));
ALTER TABLE `bulk_email_cohorttarget` ADD CONSTRAINT `bulk_emai_target_ptr_id_7974c77c83c2899d_fk_bulk_email_target_id` FOREIGN KEY (`target_ptr_id`) REFERENCES `bulk_email_target` (`id`);
ALTER TABLE `bulk_email_cohorttarget` ADD CONSTRAINT `b_cohort_id_3d66a5e8e283dba0_fk_course_groups_courseusergroup_id` FOREIGN KEY (`cohort_id`) REFERENCES `course_groups_courseusergroup` (`id`);
ALTER TABLE `bulk_email_courseemail_targets` ADD CONSTRAINT `bul_courseemail_id_47818d2b9b38e0e0_fk_bulk_email_courseemail_id` FOREIGN KEY (`courseemail_id`) REFERENCES `bulk_email_courseemail` (`id`);
ALTER TABLE `bulk_email_courseemail_targets` ADD CONSTRAINT `bulk_email_co_target_id_6cdcd92a52b1f9d9_fk_bulk_email_target_id` FOREIGN KEY (`target_id`) REFERENCES `bulk_email_target` (`id`);

COMMIT;
/*============bulk_email	0005=============================*/
BEGIN;
--
-- MIGRATION NOW PERFORMS OPERATION THAT CANNOT BE WRITTEN AS SQL:
-- Raw Python operation
--

COMMIT;
/*============certificates	0008=============================*/
/*============commerce	0002=============================*/
BEGIN;
CREATE TABLE `commerce_commerceconfiguration` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `checkout_on_ecommerce_service` bool NOT NULL, `single_course_checkout_page` varchar(255) NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `commerce_commerceconfiguration` ADD CONSTRAINT `commerce_commerce_changed_by_id_7441951d1c97c1d7_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============commerce	0003=============================*/
/*============commerce	0004=============================*/
BEGIN;
ALTER TABLE `commerce_commerceconfiguration` ADD COLUMN `cache_ttl` integer UNSIGNED DEFAULT 0 NOT NULL;
ALTER TABLE `commerce_commerceconfiguration` ALTER COLUMN `cache_ttl` DROP DEFAULT;
ALTER TABLE `commerce_commerceconfiguration` ADD COLUMN `receipt_page` varchar(255) DEFAULT '/commerce/checkout/receipt/?orderNum=' NOT NULL;
ALTER TABLE `commerce_commerceconfiguration` ALTER COLUMN `receipt_page` DROP DEFAULT;

COMMIT;
/*============contentserver	0001=============================*/
BEGIN;
CREATE TABLE `contentserver_courseassetcachettlconfig` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `cache_ttl` integer UNSIGNED NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `contentserver_courseassetcachettlconfig` ADD CONSTRAINT `contentserver_cou_changed_by_id_3b5e5ff6c6df495d_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============contentserver	0002=============================*/
BEGIN;
CREATE TABLE `contentserver_cdnuseragentsconfig` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `cdn_user_agents` longtext NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `contentserver_cdnuseragentsconfig` ADD CONSTRAINT `contentserver_cdn_changed_by_id_36fe2b67b2c7f0ba_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============course_modes	0005=============================*/
/*============course_modes	0006=============================*/
/*============course_modes	0007=============================*/
BEGIN;
ALTER TABLE `course_modes_coursemode` ADD COLUMN `bulk_sku` varchar(255) NULL;

COMMIT;
/*============course_overviews	0006=============================*/
BEGIN;
CREATE TABLE `course_overviews_courseoverviewimageset` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `small_url` longtext NOT NULL, `large_url` longtext NOT NULL, `course_overview_id` varchar(255) NOT NULL UNIQUE);
ALTER TABLE `course_overviews_courseoverviewimageset` ADD CONSTRAINT `D47baf904f8952eb0e1fafefd558a718` FOREIGN KEY (`course_overview_id`) REFERENCES `course_overviews_courseoverview` (`id`);

COMMIT;
/*============course_overviews	0007=============================*/
BEGIN;
CREATE TABLE `course_overviews_courseoverviewimageconfig` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `small_width` integer NOT NULL, `small_height` integer NOT NULL, `large_width` integer NOT NULL, `large_height` integer NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `course_overviews_courseoverviewimageconfig` ADD CONSTRAINT `course_overviews__changed_by_id_54b19ba1c134af6a_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============course_overviews	0008=============================*/
/*============course_overviews	0009=============================*/
/*
BEGIN;
ALTER TABLE `course_overviews_courseoverview` ADD COLUMN `facebook_url` longtext NULL;

COMMIT;
*/
/*============course_overviews	0010=============================*/
BEGIN;
/*ALTER TABLE `course_overviews_courseoverview` DROP COLUMN `facebook_url` CASCADE;*/
ALTER TABLE `course_overviews_courseoverview` ADD COLUMN `self_paced` bool DEFAULT 0 NOT NULL;
ALTER TABLE `course_overviews_courseoverview` ALTER COLUMN `self_paced` DROP DEFAULT;

COMMIT;
/*============coursetalk	0001=============================*/
BEGIN;
CREATE TABLE `coursetalk_coursetalkwidgetconfiguration` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `platform_key` varchar(50) NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `coursetalk_coursetalkwidgetconfiguration` ADD CONSTRAINT `coursetalk_course_changed_by_id_18bd24020c1b37d5_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============coursetalk	0002=============================*/
/*============coursewarehistoryextended	0001=============================*/
/*============coursewarehistoryextended	0002=============================*/
/*============credentials	0001=============================*/
BEGIN;
CREATE TABLE `credentials_credentialsapiconfig` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `internal_service_url` varchar(200) NOT NULL, `public_service_url` varchar(200) NOT NULL, `enable_learner_issuance` bool NOT NULL, `enable_studio_authoring` bool NOT NULL, `cache_ttl` integer UNSIGNED NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `credentials_credentialsapiconfig` ADD CONSTRAINT `credentials_crede_changed_by_id_273a2e6b0649c861_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============credentials	0002=============================*/
/*============credit	0002=============================*/
BEGIN;
CREATE TABLE `credit_creditconfig` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `cache_ttl` integer UNSIGNED NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `credit_creditconfig` ADD CONSTRAINT `credit_creditconf_changed_by_id_6270a800475f6694_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============credit	0003=============================*/
/*============django_comment_common	0002=============================*/
BEGIN;
CREATE TABLE `django_comment_common_forumsconfig` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `connection_timeout` double precision NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `django_comment_common_forumsconfig` ADD CONSTRAINT `django_comment_co_changed_by_id_18a7f46ff6309996_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============edx_proctoring	0002=============================*/
BEGIN;
ALTER TABLE `proctoring_proctoredexamstudentattempt` ADD COLUMN `is_status_acknowledged` bool DEFAULT 0 NOT NULL;
ALTER TABLE `proctoring_proctoredexamstudentattempt` ALTER COLUMN `is_status_acknowledged` DROP DEFAULT;

COMMIT;
/*============edx_proctoring	0003=============================*/
/*============edx_proctoring	0004=============================*/
BEGIN;
ALTER TABLE `proctoring_proctoredexamsoftwaresecurereview` ADD CONSTRAINT `proctoring_proctoredexamsoftw_attempt_code_69b9866a54964afb_uniq` UNIQUE (`attempt_code`);

COMMIT;
/*============edx_proctoring	0005=============================*/
BEGIN;
ALTER TABLE `proctoring_proctoredexam` ADD COLUMN `hide_after_due` bool DEFAULT 0 NOT NULL;
ALTER TABLE `proctoring_proctoredexam` ALTER COLUMN `hide_after_due` DROP DEFAULT;

COMMIT;
/*============email_marketing	0001=============================*/
BEGIN;
CREATE TABLE `email_marketing_emailmarketingconfiguration` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `sailthru_key` varchar(32) NOT NULL, `sailthru_secret` varchar(32) NOT NULL, `sailthru_new_user_list` varchar(48) NOT NULL, `sailthru_retry_interval` integer NOT NULL, `sailthru_max_retries` integer NOT NULL, `sailthru_activation_template` varchar(20) NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `email_marketing_emailmarketingconfiguration` ADD CONSTRAINT `email_marketing_e_changed_by_id_1c6968b921f23b0b_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============email_marketing	0002=============================*/
BEGIN;
ALTER TABLE `email_marketing_emailmarketingconfiguration` ADD COLUMN `sailthru_abandoned_cart_delay` integer DEFAULT 60 NOT NULL;
ALTER TABLE `email_marketing_emailmarketingconfiguration` ALTER COLUMN `sailthru_abandoned_cart_delay` DROP DEFAULT;
ALTER TABLE `email_marketing_emailmarketingconfiguration` ADD COLUMN `sailthru_abandoned_cart_template` varchar(20) NOT NULL;
ALTER TABLE `email_marketing_emailmarketingconfiguration` ADD COLUMN `sailthru_content_cache_age` integer DEFAULT 3600 NOT NULL;
ALTER TABLE `email_marketing_emailmarketingconfiguration` ALTER COLUMN `sailthru_content_cache_age` DROP DEFAULT;
ALTER TABLE `email_marketing_emailmarketingconfiguration` ADD COLUMN `sailthru_enroll_cost` integer DEFAULT 100 NOT NULL;
ALTER TABLE `email_marketing_emailmarketingconfiguration` ALTER COLUMN `sailthru_enroll_cost` DROP DEFAULT;
ALTER TABLE `email_marketing_emailmarketingconfiguration` ADD COLUMN `sailthru_enroll_template` varchar(20) NOT NULL;
ALTER TABLE `email_marketing_emailmarketingconfiguration` ADD COLUMN `sailthru_get_tags_from_sailthru` bool DEFAULT 1 NOT NULL;
ALTER TABLE `email_marketing_emailmarketingconfiguration` ALTER COLUMN `sailthru_get_tags_from_sailthru` DROP DEFAULT;
ALTER TABLE `email_marketing_emailmarketingconfiguration` ADD COLUMN `sailthru_purchase_template` varchar(20) NOT NULL;
ALTER TABLE `email_marketing_emailmarketingconfiguration` ADD COLUMN `sailthru_upgrade_template` varchar(20) NOT NULL;
COMMIT;
/*============microsite_configuration	0001=============================*/
BEGIN;
CREATE TABLE `microsite_configuration_historicalmicrositeorganizationmapping` (`id` integer NOT NULL, `organization` varchar(63) NOT NULL, `history_id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `history_date` datetime(6) NOT NULL, `history_type` varchar(1) NOT NULL, `history_user_id` integer NULL);
CREATE TABLE `microsite_configuration_historicalmicrositetemplate` (`id` integer NOT NULL, `template_uri` varchar(255) NOT NULL, `template` longtext NOT NULL, `history_id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `history_date` datetime(6) NOT NULL, `history_type` varchar(1) NOT NULL, `history_user_id` integer NULL);
CREATE TABLE `microsite_configuration_microsite` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `key` varchar(63) NOT NULL UNIQUE, `values` longtext NOT NULL, `site_id` integer NOT NULL UNIQUE);
CREATE TABLE `microsite_configuration_micrositehistory` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `key` varchar(63) NOT NULL UNIQUE, `values` longtext NOT NULL, `site_id` integer NOT NULL UNIQUE);
CREATE TABLE `microsite_configuration_micrositeorganizationmapping` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `organization` varchar(63) NOT NULL UNIQUE, `microsite_id` integer NOT NULL);
CREATE TABLE `microsite_configuration_micrositetemplate` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `template_uri` varchar(255) NOT NULL, `template` longtext NOT NULL, `microsite_id` integer NOT NULL);
ALTER TABLE `microsite_configuration_historicalmicrositetemplate` ADD COLUMN `microsite_id` integer NULL;
ALTER TABLE `microsite_configuration_historicalmicrositetemplate` ALTER COLUMN `microsite_id` DROP DEFAULT;
ALTER TABLE `microsite_configuration_historicalmicrositeorganizationmapping` ADD COLUMN `microsite_id` integer NULL;
ALTER TABLE `microsite_configuration_historicalmicrositeorganizationmapping` ALTER COLUMN `microsite_id` DROP DEFAULT;
ALTER TABLE `microsite_configuration_micrositetemplate` ADD CONSTRAINT `microsite_configuration_micros_microsite_id_80b3f3616d2e317_uniq` UNIQUE (`microsite_id`, `template_uri`);
ALTER TABLE `microsite_configuration_historicalmicrositeorganizationmapping` ADD CONSTRAINT `microsite_confi_history_user_id_40846fe04877dd35_fk_auth_user_id` FOREIGN KEY (`history_user_id`) REFERENCES `auth_user` (`id`);
CREATE INDEX `microsite_configuration_historicalmicrositeorganizationmappi1219` ON `microsite_configuration_historicalmicrositeorganizationmapping` (`id`);
CREATE INDEX `microsite_configuration_historicalmicrositeorganizationmappi74d9` ON `microsite_configuration_historicalmicrositeorganizationmapping` (`organization`);
ALTER TABLE `microsite_configuration_historicalmicrositetemplate` ADD CONSTRAINT `microsite_confi_history_user_id_53e1b0dcb708d6ef_fk_auth_user_id` FOREIGN KEY (`history_user_id`) REFERENCES `auth_user` (`id`);
CREATE INDEX `microsite_configuration_historicalmicrositetemplate_b80bb774` ON `microsite_configuration_historicalmicrositetemplate` (`id`);
CREATE INDEX `microsite_configuration_historicalmicrositetemplate_a8b249ec` ON `microsite_configuration_historicalmicrositetemplate` (`template_uri`);
ALTER TABLE `microsite_configuration_microsite` ADD CONSTRAINT `microsite_configuratio_site_id_3ebe20a76de5aa4_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`);
ALTER TABLE `microsite_configuration_micrositehistory` ADD CONSTRAINT `microsite_configurati_site_id_6977a04d3625a533_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`);
ALTER TABLE `microsite_configuration_micrositeorganizationmapping` ADD CONSTRAINT `D1c5d7dbbb2cde12ce18b38d46f71ee0` FOREIGN KEY (`microsite_id`) REFERENCES `microsite_configuration_microsite` (`id`);
ALTER TABLE `microsite_configuration_micrositetemplate` ADD CONSTRAINT `D4919cbc5f1414d3de93aa9ec9aa48f3` FOREIGN KEY (`microsite_id`) REFERENCES `microsite_configuration_microsite` (`id`);
CREATE INDEX `microsite_configuration_micrositetemplate_a8b249ec` ON `microsite_configuration_micrositetemplate` (`template_uri`);
CREATE INDEX `microsite_configuration_historicalmicrositetemplate_c9cd58ae` ON `microsite_configuration_historicalmicrositetemplate` (`microsite_id`);
CREATE INDEX `microsite_configuration_historicalmicrositeorganizationmappi5a96` ON `microsite_configuration_historicalmicrositeorganizationmapping` (`microsite_id`);

COMMIT;
/*============microsite_configuration	0002=============================*/
BEGIN;
ALTER TABLE `microsite_configuration_micrositehistory` DROP FOREIGN KEY `microsite_configurati_site_id_6977a04d3625a533_fk_django_site_id`;
ALTER TABLE `microsite_configuration_micrositehistory` ADD CONSTRAINT `microsite_configurati_site_id_6977a04d3625a533_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`);

COMMIT;
/*============milestones	0003=============================*/
BEGIN;
ALTER TABLE `milestones_coursecontentmilestone` ADD COLUMN `requirements` varchar(255) NULL;
ALTER TABLE `milestones_coursecontentmilestone` ALTER COLUMN `requirements` DROP DEFAULT;

COMMIT;
/*============milestones	0004=============================*/
BEGIN;
CREATE INDEX `milestones_coursecontentmilestone_active_39b5c645fa33bfee_uniq` ON `milestones_coursecontentmilestone` (`active`);
CREATE INDEX `milestones_coursemilestone_active_5c3a925f8cc4bde2_uniq` ON `milestones_coursemilestone` (`active`);
CREATE INDEX `milestones_milestone_active_1182ba3c09d42c35_uniq` ON `milestones_milestone` (`active`);
CREATE INDEX `milestones_usermilestone_active_1827f467fe87a8ea_uniq` ON `milestones_usermilestone` (`active`);

COMMIT;
/*============mobile_api	0002=============================*/
BEGIN;
CREATE TABLE `mobile_api_appversionconfig` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `platform` varchar(50) NOT NULL, `version` varchar(50) NOT NULL, `major_version` integer NOT NULL, `minor_version` integer NOT NULL, `patch_version` integer NOT NULL, `expire_at` datetime(6) NULL, `enabled` bool NOT NULL, `created_at` datetime(6) NOT NULL, `updated_at` datetime(6) NOT NULL);
ALTER TABLE `mobile_api_appversionconfig` ADD CONSTRAINT `mobile_api_appversionconfig_platform_d34993f68d46008_uniq` UNIQUE (`platform`, `version`);

COMMIT;
/*============oauth2	0002=============================*/
BEGIN;
ALTER TABLE `oauth2_accesstoken` DROP FOREIGN KEY `oauth2_accesstoken_user_id_7a865c7085722378_fk_auth_user_id`;
ALTER TABLE `oauth2_accesstoken` ADD CONSTRAINT `oauth2_accesstoken_user_id_7a865c7085722378_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);
ALTER TABLE `oauth2_grant` DROP FOREIGN KEY `oauth2_grant_user_id_3de96a461bb76819_fk_auth_user_id`;
ALTER TABLE `oauth2_grant` ADD CONSTRAINT `oauth2_grant_user_id_3de96a461bb76819_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);
ALTER TABLE `oauth2_refreshtoken` DROP FOREIGN KEY `oauth2_refreshtoken_user_id_acecf94460b787c_fk_auth_user_id`;
ALTER TABLE `oauth2_refreshtoken` ADD CONSTRAINT `oauth2_refreshtoken_user_id_acecf94460b787c_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============oauth2	0003=============================*/
BEGIN;
ALTER TABLE `oauth2_client` ADD COLUMN `logout_uri` varchar(200) NULL;
ALTER TABLE `oauth2_client` ALTER COLUMN `logout_uri` DROP DEFAULT;

COMMIT;
/*============oauth2_provider	0001=============================*/
BEGIN;
CREATE TABLE `oauth2_provider_application` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `client_id` varchar(100) NOT NULL UNIQUE, `redirect_uris` longtext NOT NULL, `client_type` varchar(32) NOT NULL, `authorization_grant_type` varchar(32) NOT NULL, `client_secret` varchar(255) NOT NULL, `name` varchar(255) NOT NULL, `user_id` integer NOT NULL);
CREATE TABLE `oauth2_provider_accesstoken` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `token` varchar(255) NOT NULL, `expires` datetime(6) NOT NULL, `scope` longtext NOT NULL, `application_id` integer NOT NULL, `user_id` integer NOT NULL);
CREATE TABLE `oauth2_provider_grant` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `code` varchar(255) NOT NULL, `expires` datetime(6) NOT NULL, `redirect_uri` varchar(255) NOT NULL, `scope` longtext NOT NULL, `application_id` integer NOT NULL, `user_id` integer NOT NULL);
CREATE TABLE `oauth2_provider_refreshtoken` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `token` varchar(255) NOT NULL, `access_token_id` integer NOT NULL UNIQUE, `application_id` integer NOT NULL, `user_id` integer NOT NULL);
ALTER TABLE `oauth2_provider_application` ADD CONSTRAINT `oauth2_provider_applica_user_id_7fa13387c260b798_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);
CREATE INDEX `oauth2_provider_application_9d667c2b` ON `oauth2_provider_application` (`client_secret`);
ALTER TABLE `oauth2_provider_accesstoken` ADD CONSTRAINT `D5ac3019ee1c474fd85718b015e3d3a1` FOREIGN KEY (`application_id`) REFERENCES `oauth2_provider_application` (`id`);
ALTER TABLE `oauth2_provider_accesstoken` ADD CONSTRAINT `oauth2_provider_accesst_user_id_5e2f004fdebea22d_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);
CREATE INDEX `oauth2_provider_accesstoken_94a08da1` ON `oauth2_provider_accesstoken` (`token`);
ALTER TABLE `oauth2_provider_grant` ADD CONSTRAINT `D6b2a4f1402d4f338b690c38b795830a` FOREIGN KEY (`application_id`) REFERENCES `oauth2_provider_application` (`id`);
ALTER TABLE `oauth2_provider_grant` ADD CONSTRAINT `oauth2_provider_grant_user_id_3111344894d452da_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);
CREATE INDEX `oauth2_provider_grant_c1336794` ON `oauth2_provider_grant` (`code`);
ALTER TABLE `oauth2_provider_refreshtoken` ADD CONSTRAINT `b58d9cb3b93afb36b11b7741bf1bcc1a` FOREIGN KEY (`access_token_id`) REFERENCES `oauth2_provider_accesstoken` (`id`);
ALTER TABLE `oauth2_provider_refreshtoken` ADD CONSTRAINT `d3e264ceec355cabed6ff9976fc42a06` FOREIGN KEY (`application_id`) REFERENCES `oauth2_provider_application` (`id`);
ALTER TABLE `oauth2_provider_refreshtoken` ADD CONSTRAINT `oauth2_provider_refresh_user_id_3f695b639cfbc9a3_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);
CREATE INDEX `oauth2_provider_refreshtoken_94a08da1` ON `oauth2_provider_refreshtoken` (`token`);

COMMIT;
/*============oauth2_provider	0002=============================*/
BEGIN;
ALTER TABLE `oauth2_provider_application` ADD COLUMN `skip_authorization` bool DEFAULT 0 NOT NULL;
ALTER TABLE `oauth2_provider_application` ALTER COLUMN `skip_authorization` DROP DEFAULT;
ALTER TABLE `oauth2_provider_application` DROP FOREIGN KEY `oauth2_provider_applica_user_id_7fa13387c260b798_fk_auth_user_id`;
ALTER TABLE `oauth2_provider_application` ADD CONSTRAINT `oauth2_provider_applica_user_id_7fa13387c260b798_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);
ALTER TABLE `oauth2_provider_accesstoken` DROP FOREIGN KEY `oauth2_provider_accesst_user_id_5e2f004fdebea22d_fk_auth_user_id`;
ALTER TABLE `oauth2_provider_accesstoken` MODIFY `user_id` integer NULL;
ALTER TABLE `oauth2_provider_accesstoken` ADD CONSTRAINT `oauth2_provider_accesst_user_id_5e2f004fdebea22d_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============programs	0004=============================*/
BEGIN;
ALTER TABLE `programs_programsapiconfig` ADD COLUMN `enable_certification` bool DEFAULT 0 NOT NULL;
ALTER TABLE `programs_programsapiconfig` ALTER COLUMN `enable_certification` DROP DEFAULT;

COMMIT;
/*============programs	0005=============================*/
BEGIN;
ALTER TABLE `programs_programsapiconfig` ADD COLUMN `max_retries` integer UNSIGNED DEFAULT 11 NOT NULL;
ALTER TABLE `programs_programsapiconfig` ALTER COLUMN `max_retries` DROP DEFAULT;

COMMIT;
/*============programs	0006=============================*/
BEGIN;
ALTER TABLE `programs_programsapiconfig` ADD COLUMN `xseries_ad_enabled` bool DEFAULT 0 NOT NULL;
ALTER TABLE `programs_programsapiconfig` ALTER COLUMN `xseries_ad_enabled` DROP DEFAULT;

COMMIT;
/*============programs	0007=============================*/
BEGIN;
ALTER TABLE `programs_programsapiconfig` ADD COLUMN `program_listing_enabled` bool DEFAULT 0 NOT NULL;
ALTER TABLE `programs_programsapiconfig` ALTER COLUMN `program_listing_enabled` DROP DEFAULT;

COMMIT;
/*============programs	0008=============================*/
BEGIN;
ALTER TABLE `programs_programsapiconfig` ADD COLUMN `program_details_enabled` bool DEFAULT 0 NOT NULL;
ALTER TABLE `programs_programsapiconfig` ALTER COLUMN `program_details_enabled` DROP DEFAULT;

COMMIT;
/*============redirects	0001=============================*/
BEGIN;
CREATE TABLE `django_redirect` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `site_id` integer NOT NULL, `old_path` varchar(200) NOT NULL, `new_path` varchar(200) NOT NULL, UNIQUE (`site_id`, `old_path`));
ALTER TABLE `django_redirect` ADD CONSTRAINT `django_redirect_site_id_121a4403f653e524_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`);
CREATE INDEX `django_redirect_91a0b591` ON `django_redirect` (`old_path`);

COMMIT;
/*============rss_proxy	0001=============================*/
BEGIN;
CREATE TABLE `rss_proxy_whitelistedrssurl` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `url` varchar(255) NOT NULL UNIQUE);

COMMIT;
/*============shoppingcart	0003=============================*/
BEGIN;
ALTER TABLE `shoppingcart_courseregcodeitem` ALTER COLUMN `mode` SET DEFAULT 'honor';
ALTER TABLE `shoppingcart_courseregcodeitem` ALTER COLUMN `mode` DROP DEFAULT;
ALTER TABLE `shoppingcart_paidcourseregistration` ALTER COLUMN `mode` SET DEFAULT 'honor';
ALTER TABLE `shoppingcart_paidcourseregistration` ALTER COLUMN `mode` DROP DEFAULT;

COMMIT;
/*============site_configuration	0001=============================*/
BEGIN;
CREATE TABLE `site_configuration_siteconfiguration` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `values` longtext NOT NULL, `site_id` integer NOT NULL UNIQUE);
CREATE TABLE `site_configuration_siteconfigurationhistory` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `values` longtext NOT NULL, `site_id` integer NOT NULL);
ALTER TABLE `site_configuration_siteconfiguration` ADD CONSTRAINT `site_configuration_si_site_id_51c4aa24ab9238cb_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`);
ALTER TABLE `site_configuration_siteconfigurationhistory` ADD CONSTRAINT `site_configuration_si_site_id_20c9c1a5f8c3358e_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`);

COMMIT;
/*============site_configuration	0002=============================*/
BEGIN;
ALTER TABLE `site_configuration_siteconfiguration` ADD COLUMN `enabled` bool DEFAULT 0 NOT NULL;
ALTER TABLE `site_configuration_siteconfiguration` ALTER COLUMN `enabled` DROP DEFAULT;
ALTER TABLE `site_configuration_siteconfigurationhistory` ADD COLUMN `enabled` bool DEFAULT 0 NOT NULL;
ALTER TABLE `site_configuration_siteconfigurationhistory` ALTER COLUMN `enabled` DROP DEFAULT;

COMMIT;
/*============static_replace	0001=============================*/
BEGIN;
CREATE TABLE `static_replace_assetbaseurlconfig` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `base_url` longtext NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `static_replace_assetbaseurlconfig` ADD CONSTRAINT `static_replace_as_changed_by_id_796c2e5b1bee7027_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============static_replace	0002=============================*/
BEGIN;
CREATE TABLE `static_replace_assetexcludedextensionsconfig` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `excluded_extensions` longtext NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `static_replace_assetexcludedextensionsconfig` ADD CONSTRAINT `static_replace_as_changed_by_id_5885827de4f271dc_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============student	0003=============================*/
BEGIN;
CREATE TABLE `student_userattribute` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `created` datetime(6) NOT NULL, `modified` datetime(6) NOT NULL, `name` varchar(255) NOT NULL, `value` varchar(255) NOT NULL, `user_id` integer NOT NULL);
ALTER TABLE `student_userattribute` ADD CONSTRAINT `student_userattribute_user_id_395f02bcb61d19c1_uniq` UNIQUE (`user_id`, `name`);
ALTER TABLE `student_userattribute` ADD CONSTRAINT `student_userattribute_user_id_1d4fc3ed612e93e5_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============student	0004=============================*/
/*============student	0005=============================*/
BEGIN;
CREATE INDEX `student_userattribute_name_5fd741d8c66ce242_uniq` ON `student_userattribute` (`name`);

COMMIT;
/*============student	0006=============================*/
BEGIN;
CREATE TABLE `student_logoutviewconfiguration` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `student_logoutviewconfiguration` ADD CONSTRAINT `student_logoutvie_changed_by_id_71e69e1e508e4fce_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*============submissions	0003=============================*/
BEGIN;
ALTER TABLE `submissions_submission` ADD COLUMN `status` varchar(1) DEFAULT 'A' NOT NULL;
ALTER TABLE `submissions_submission` ALTER COLUMN `status` DROP DEFAULT;

COMMIT;
/*============theming	0001=============================*/
BEGIN;
CREATE TABLE `theming_sitetheme` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `theme_dir_name` varchar(255) NOT NULL, `site_id` integer NOT NULL);
ALTER TABLE `theming_sitetheme` ADD CONSTRAINT `theming_sitetheme_site_id_4fccdacaebfeb01f_fk_django_site_id` FOREIGN KEY (`site_id`) REFERENCES `django_site` (`id`);

COMMIT;
/*============third_party_auth	0002=============================*/
BEGIN;
ALTER TABLE `third_party_auth_ltiproviderconfig` ADD COLUMN `icon_image` varchar(100) NOT NULL;
ALTER TABLE `third_party_auth_oauth2providerconfig` ADD COLUMN `icon_image` varchar(100) NOT NULL;
ALTER TABLE `third_party_auth_samlproviderconfig` ADD COLUMN `icon_image` varchar(100) NOT NULL;
COMMIT;
/*============verified_track_content	0001=============================*/
BEGIN;
CREATE TABLE `verified_track_content_verifiedtrackcohortedcourse` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `course_key` varchar(255) NOT NULL UNIQUE, `enabled` bool NOT NULL);

COMMIT;
/*============verified_track_content	0002=============================*/
BEGIN;
ALTER TABLE `verified_track_content_verifiedtrackcohortedcourse` ADD COLUMN `verified_cohort_name` varchar(100) DEFAULT 'Verified Learners' NOT NULL;
ALTER TABLE `verified_track_content_verifiedtrackcohortedcourse` ALTER COLUMN `verified_cohort_name` DROP DEFAULT;

COMMIT;
/*============wiki	0003=============================*/
BEGIN;
ALTER TABLE `wiki_articlerevision` MODIFY `ip_address` char(39) NULL;
ALTER TABLE `wiki_attachmentrevision` MODIFY `ip_address` char(39) NULL;
ALTER TABLE `wiki_revisionpluginrevision` MODIFY `ip_address` char(39) NULL;

COMMIT;
/*============xblock_django	0002=============================*/
BEGIN;
ALTER TABLE `xblock_django_xblockdisableconfig` ADD COLUMN `disabled_create_blocks` longtext NOT NULL;
UPDATE `xblock_django_xblockdisableconfig` SET `disabled_create_blocks` = '';

COMMIT;
/*============xblock_django	0003=============================*/
BEGIN;
CREATE TABLE `xblock_django_xblockconfiguration` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `name` varchar(255) NOT NULL, `deprecated` bool NOT NULL, `changed_by_id` integer NULL);
CREATE TABLE `xblock_django_xblockstudioconfiguration` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `name` varchar(255) NOT NULL, `template` varchar(255) NOT NULL, `support_level` varchar(2) NOT NULL, `changed_by_id` integer NULL);
CREATE TABLE `xblock_django_xblockstudioconfigurationflag` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `change_date` datetime(6) NOT NULL, `enabled` bool NOT NULL, `changed_by_id` integer NULL);
ALTER TABLE `xblock_django_xblockconfiguration` ADD CONSTRAINT `xblock_django_xbl_changed_by_id_61068ae9f50d6490_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);
CREATE INDEX `xblock_django_xblockconfiguration_b068931c` ON `xblock_django_xblockconfiguration` (`name`);
ALTER TABLE `xblock_django_xblockstudioconfiguration` ADD CONSTRAINT `xblock_django_xblo_changed_by_id_353d5def0d11370_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);
CREATE INDEX `xblock_django_xblockstudioconfiguration_b068931c` ON `xblock_django_xblockstudioconfiguration` (`name`);
ALTER TABLE `xblock_django_xblockstudioconfigurationflag` ADD CONSTRAINT `xblock_django_xbl_changed_by_id_11457ce96bbbfbf6_fk_auth_user_id` FOREIGN KEY (`changed_by_id`) REFERENCES `auth_user` (`id`);

COMMIT;
/*=========================================*/
BEGIN;
CREATE TABLE `tagging_tagavailablevalues` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `value` varchar(255) NOT NULL);
CREATE TABLE `tagging_tagcategories` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `name` varchar(255) NOT NULL UNIQUE, `title` varchar(255) NOT NULL);
ALTER TABLE `tagging_tagavailablevalues` ADD COLUMN `category_id` integer NOT NULL;
ALTER TABLE `tagging_tagavailablevalues` ALTER COLUMN `category_id` DROP DEFAULT;
CREATE INDEX `tagging_tagavailablevalues_b583a629` ON `tagging_tagavailablevalues` (`category_id`);
ALTER TABLE `tagging_tagavailablevalues` ADD CONSTRAINT `tagging_category_id_40780d45c76e4f97_fk_tagging_tagcategories_id` FOREIGN KEY (`category_id`) REFERENCES `tagging_tagcategories` (`id`);

COMMIT;
