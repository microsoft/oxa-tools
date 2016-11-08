UPDATE auth_user SET is_active=False where username="staff";
UPDATE auth_user SET is_active=False where username="honor";
UPDATE auth_user SET is_active=False where username="audit";
UPDATE auth_user SET is_active=False where username="verified";

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
  '{"default":{"platform_name":"Microsoft","company_about_url":"https://www.microsoft.com/en-us/about","company_privacy_url":"https://privacy.microsoft.com/en-us/privacystatement/","company_tos_url":"https://openedx.microsoft.com/tos","logo_src":"https://openedx.microsoft.com/static/themes/default/images/ms-logo.png","logo_url":"www.microsoft.com"},"honor":{"certificate_type":"honor","certificate_title":"Honor Certificate","document_body_class_append":"is-honorcode"},"verified":{"certificate_type":"verified","certificate_title":"Verified Certificate","document_body_class_append":"is-idverified"},"base":{"certificate_type":"base","certificate_title":"Certificate of Achievement","document_body_class_append":"is-base"},"distinguished":{"certificate_type":"distinguished","certificate_title":"Distinguished Certificate of Achievement","document_body_class_append":"is-distinguished"}}'
 );

