-- Copyright (c) Microsoft Corporation. All Rights Reserved.
-- Licensed under the MIT license. See LICENSE file on the project webpage for details.
BEGIN;
CREATE DATABASE oxa;
CREATE TABLE `oxa.oxa_activationfailed` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `activation_year` int(11) NOT NULL,
  `activation_month` int(11) NOT NULL,
  `activation_day` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `email` varchar(254) NOT NULL,
  `activation_key` varchar(32) NOT NULL,
  `date_joined` datetime(6) NOT NULL,
  `date_failed` datetime(6) NOT NULL,
  `is_processed` tinyint(1) DEFAULT '0',
  `date_processed` datetime(6) DEFAULT NULL,
  `hostvmip` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `oxa_ymd_2` (`activation_year`,`activation_month`,`activation_day`),
  KEY `oxa_userid_2` (`user_id`),
  KEY `oxa_email_2` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;


 CREATE TABLE `oxa.oxa_activationsummary` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `activation_year` int(11) NOT NULL,
  `activation_month` int(11) NOT NULL,
  `activation_day` int(11) NOT NULL,
  `newaccount` int(11) DEFAULT '0',
  `activated` int(11) DEFAULT '0',
  `notactivated` int(11) DEFAULT '0',
  `failed` int(11) DEFAULT '0',
  `success` int(11) DEFAULT '0',
  `resend` int(11) DEFAULT '0',
  `maxuserid` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `u_oxa_ymd_1` (`activation_year`,`activation_month`,`activation_day`),
  KEY `oxa_ymd_1` (`activation_year`,`activation_month`,`activation_day`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 ;
COMMIT;
