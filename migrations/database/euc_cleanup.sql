/*
 When we run this SQL script it will remove the dogwood specific database tweaks 
 and it will be exactly same with upgraded eucalyptus MySQL database
*/

BEGIN;
/* DROP TABLE certificates_badgeimageconfiguration */
DROP TABLE certificates_badgeimageconfiguration;

/* DROP TABLE certificates_badgeassertion */
DROP TABLE certificates_badgeassertion;

/* ON course_overviews_courseoverview */
ALTER TABLE course_overviews_courseoverview DROP COLUMN facebook_url;
ALTER TABLE course_overviews_courseoverview ALTER self_paced DROP DEFAULT;

/* microsite_configuration_micrositehistory */
ALTER TABLE microsite_configuration_micrositehistory DROP INDEX `key`;
ALTER table microsite_configuration_micrositehistory DROP foreign key microsite_configurati_site_id_6977a04d3625a533_fk_django_site_id;
ALTER TABLE microsite_configuration_micrositehistory DROP INDEX site_id;
ALTER TABLE microsite_configuration_micrositehistory ADD CONSTRAINT microsite_configurati_site_id_6977a04d3625a533_fk_django_site_id FOREIGN KEY (site_id) REFERENCES django_site(id);
COMMIT;

