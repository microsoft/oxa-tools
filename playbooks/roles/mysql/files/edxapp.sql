/* 
  Adding unique constraint on the email column of auth_user table
  so that multiple accounts with same e-mail address cannot be created
  
  This was default behaviour in Python 2.7.3 and Django 1.4 
  but it is changed in Python 2.7.10 and Django 1.8.7

  Running this command multiple times is harmless.
*/
ALTER TABLE auth_user ADD UNIQUE (email);


/*
  Create the certificate HTML view configuration in the edxapp database which is used by Open edX and also showed on Django admin panel.

  In the certificates_certificatehtmlviewconfiguration table we can have only one certification row defined so first delete any existing ones
  and then insert the certificate. It is inserted as enabled, ready to be used in the courses.

  It is safe to run this multiple times.
*/
DELETE FROM certificates_certificatehtmlviewconfiguration;

INSERT INTO certificates_certificatehtmlviewconfiguration
(
  change_date,
  enabled,
  configuration
)
VALUES
( 
  NOW(),
  True,
  '{"default":{"platform_name":"Microsoft Learning","company_about_url":"https://www.microsoft.com/en-us/learning/default.aspx","company_privacy_url":"https://privacy.microsoft.com/en-us/privacystatement/","company_tos_url":"/tos","logo_src":"/static/images/ms-logo.png","logo_url":"http://www.microsoft.com"},"honor":{"certificate_type":"honor","certificate_title":"Honor Certificate","document_body_class_append":"is-honorcode"},"verified":{"certificate_type":"verified","certificate_title":"Verified Certificate","document_body_class_append":"is-idverified"},"base":{"certificate_type":"base","certificate_title":"Certificate of Achievement","document_body_class_append":"is-base"},"distinguished":{"certificate_type":"distinguished","certificate_title":"Distinguished Certificate of Achievement","document_body_class_append":"is-distinguished"}}'
);

/*
  Insert the entry so that self_paced courses are allowed on the platform.

  In the self_paced_selfpacedconfiguration table we can have only one row defined so first delete any existing ones
  and then insert the selfpacedconfiguration. It is inserted as enabled, ready to be used.
  
  It is safe to run this multiple times.
*/

DELETE FROM self_paced_selfpacedconfiguration;

INSERT INTO self_paced_selfpacedconfiguration 
(
  change_date,
  enabled,
  enable_course_home_improvements
) 
VALUES
(
  NOW(),
  1,
  1
);


/*
  Insert the entry so that certificate generation is allowed on the platform.

  In the certificates_certificategenerationconfiguration table we can have only one row defined so first delete any existing ones
  and then insert the certificategenerationconfiguration. It is inserted as enabled, ready to be used.

  It is safe to run this multiple times.
*/
DELETE FROM certificates_certificategenerationconfiguration;

INSERT INTO certificates_certificategenerationconfiguration 
(
  change_date,
  enabled
) 
VALUES
(
  NOW(),
  1
);

/*
  Insert an entry so that grades are persisted for LTI Labs on the platform.

  In the grades_persistentgradesenabledflag table we can have only one row defined so first delete any existing ones
  and then insert the persistentgradesenabledflag configuration.  It is inserted as enabled for all courses.

  It is safe to run this multiple times.
*/
DELETE FROM grades_persistentgradesenabledflag;

INSERT INTO grades_persistentgradesenabledflag 
(
  change_date,
  enabled,
  enabled_for_all_courses
) 
VALUES
(
  NOW(),
  1,
  1
);
commit;
