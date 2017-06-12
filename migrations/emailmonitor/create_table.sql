BEGIN;
CREATE DATABASE oxa;
CREATE TABLE `oxa.oxa_activationfailed` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `xyear` int(11) NOT NULL,
  `xmonth` int(11) NOT NULL,
  `xday` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `email` varchar(254) NOT NULL,
  `activation_key` varchar(32) NOT NULL,
  `date_joined` datetime(6) NOT NULL,
  `date_failed` datetime(6) NOT NULL,
  `is_processed` tinyint(1) DEFAULT '0',
  `date_processed` datetime(6) DEFAULT NULL,
  `hostvmip` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `oxa_ymd_2` (`xyear`,`xmonth`,`xday`),
  KEY `oxa_userid_2` (`user_id`),
  KEY `oxa_email_2` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;


 CREATE TABLE `oxa.oxa_activationsummary` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `xyear` int(11) NOT NULL,
  `xmonth` int(11) NOT NULL,
  `xday` int(11) NOT NULL,
  `newaccount` int(11) DEFAULT '0',
  `activated` int(11) DEFAULT '0',
  `notactivated` int(11) DEFAULT '0',
  `failed` int(11) DEFAULT '0',
  `success` int(11) DEFAULT '0',
  `resend` int(11) DEFAULT '0',
  `maxuserid` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `u_oxa_ymd_1` (`xyear`,`xmonth`,`xday`),
  KEY `oxa_ymd_1` (`xyear`,`xmonth`,`xday`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 ;
COMMIT;
