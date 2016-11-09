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

