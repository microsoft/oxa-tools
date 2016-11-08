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
  Create the certificate HTML view configuration
  In the certificates_certificatehtmlviewconfiguration table we can have only one certification row defined so first delete any existing ones
  and then insret the certificate. It is inserted as enabled, ready to be used in the courses.
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
  '{"default": {"accomplishment_class_append": "accomplishment-certificate", "platform_name": "Your Platform Name Here", "logo_src": "/static/certificates/images/logo.png", "logo_url": "http://www.example.com", "company_verified_certificate_url": "http://www.example.com/verified-certificate", "company_privacy_url": "http://www.example.com/privacy-policy", "company_tos_url": "http://www.example.com/terms-service", "company_about_url": "http://www.example.com/about-us"}, "verified": {"certificate_type": "Verified", "certificate_title": "Verified Certificate of Achievement"}, "honor": {"certificate_type": "Honor Code", "certificate_title": "Certificate of Achievement"}}'
 );

