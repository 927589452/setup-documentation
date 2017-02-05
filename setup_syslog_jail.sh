#!/bin/tcsh
#https://stackoverflow.com/questions/3557037/appending-a-line-to-a-file-only-if-it-doesnt-already-exist-using-sed
#grep -q -F 'include "/configs/projectname.conf"' foo.bar || echo 'include "/configs/projectname.conf"' >> foo.bar
#https://forums.freenas.org/index.php?threads/how-to-install-a-syslog-server-jail.30357/
#https://stackoverflow.com/questions/15091785/check-if-line-exists-in-a-file
#grep -Fxq "foobar line" file || sed -i '/^context line$/i foobar line' file
#https://stackoverflow.com/questions/20267910/how-to-add-a-line-in-sed-if-not-match-is-found
#grep -q '^option' file && sed -i 's/^option.*/option=value/' file || echo 'option=value' >> file
########Setup rc.conf
OPTION=sshd_enable;VALUE="YES";FILE=/etc/rc.conf
grep -q '^$OPTION' $FILE  && sed -i 's/^$OPTION.*/$OPTION=$VALUE/' $FILE || echo '$OPTION=$VALUE' >> $FILE
OPTION=hostname;VALUE="syslog";FILE=/etc/rc.conf
grep -q '^$OPTION' $FILE  && sed -i 's/^$OPTION.*/$OPTION=$VALUE/' $FILE || echo '$OPTION=$VALUE' >> $FILE
OPTION=syslogd_enable;VALUE="NO";FILE=/etc/rc.conf
grep -q '^$OPTION' $FILE  && sed -i 's/^$OPTION.*/$OPTION=$VALUE/' $FILE || echo '$OPTION=$VALUE' >> $FILE
OPTION=rsyslogd_enable;VALUE="YES";FILE=/etc/rc.conf
grep -q '^$OPTION' $FILE  && sed -i 's/^$OPTION.*/$OPTION=$VALUE/' $FILE || echo '$OPTION=$VALUE' >> $FILE
OPTION=mysql_enable;VALUE="YES";FILE=/etc/rc.conf
grep -q '^$OPTION' $FILE  && sed -i 's/^$OPTION.*/$OPTION=$VALUE/' $FILE || echo '$OPTION=$VALUE' >> $FILE
OPTION=rsyslogd_pidfile;VALUE="/var/run/syslog.pid";FILE=/etc/rc.conf
grep -q '^$OPTION' $FILE  && sed -i 's/^$OPTION.*/$OPTION=$VALUE/' $FILE || echo '$OPTION=$VALUE' >> $FILE
OPTION=apache24_enable;VALUE="YES";FILE=/etc/rc.conf
grep -q '^$OPTION' $FILE  && sed -i 's/^$OPTION.*/$OPTION=$VALUE/' $FILE || echo '$OPTION=$VALUE' >> $FILE
#########Setup sshd_conf
OPTION=PermitRootLogin;VALUE=without-password;FILE=/etc/ssh/sshd_config
grep -q '^$OPTION' $FILE  && sed -i 's/^$OPTION.*/$OPTION\ $VALUE/' $FILE || echo '$OPTION $VALUE' >> $FILE
#########
service sshd start
#ports
portsnap fetch extract
cd /usr/ports/ports-mgmt/pkg && make deinstall clean
cd /usr/ports/ports-mgmt/pkg && make install clean BATCH=yes
pkg update
pkg upgrade
cd /usr/ports/lang/perl5.20/ && make install clean BATCH=yes
cd /usr/ports/misc/help2man && make install clean
cd /usr/ports/ftp/wget && make install clean BATCH=yes
#webserver
cd /usr/ports/www/apache24 && make install clean BATCH=yes
cd /usr/ports/lang/php56/ && make install clean BATCH=yes
cd /usr/ports/www/php56-session/ && make install clean BATCH=yes
cd /usr/ports/graphics/php56-gd && make install clean BATCH=yes
cd /usr/ports/www/mod_php56 && make install clean BATCH=yes
cd /usr/ports/converters/php56-mbstring && make install clean BATCH=yes
cd /usr/ports/devel/php56-json && make install clean BATCH=yes

#httpd.conf
$FILE= /usr/local/etc/apache24/httpd.conf
OPTION="ServerName"; VALUE="syslogserver.local"
grep -q '^$OPTION' $FILE  && sed -i 's/^$OPTION.*/$OPTION\ $VALUE/' $FILE || echo '$OPTION $VALUE' >> $FILE
OPTION="DirectoryIndex";VALUE="index.html index.php"
grep -q '^$OPTION' $FILE  && sed -i 's/^$OPTION.*/$OPTION\ $VALUE/' $FILE || echo '$OPTION $VALUE' >> $FILE
echo '
<FilesMatch "\.php$">
  SetHandler application/x-httpd-php
</FilesMatch>
<FilesMatch "\.phps$">
  SetHandler application/x-httpd-php-source
</FilesMatch>
 
Alias /phpmyadmin "/usr/local/www/phpMyAdmin"
 
<Directory "/usr/local/www/phpMyAdmin">
Options None
AllowOverride None
Require all granted
</Directory>
' >> $FILE
service apache24 restart

#db & phpmyadmin
cd /usr/ports/databases/php56-mysql && make install clean BATCH=yes
cd /usr/ports/databases/mysql56-server/ && make install clean BATCH=yes
#cd /usr/ports/databases/phpmyadmin && make install clean BATCH=yes
#ln -s /usr/local/www/phpMyAdmin /usr/local/www/apache24/data/phpMyAdmin


#mysql setup
service mysql-server status
OPTION="SET PASSWORD FOR";PASS="qazWSX";FILE=~/mysql-init.txt
grep -q '^$OPTION' $FILE  && sed -i 's/^$OPTION.*/$OPTION\ 'root*\@'localhost' = PASSWORD/'$PASS')/' $FILE || echo "$OPTION\ 'root*\@'localhost' = PASSWORD/'$PASS')" >> $FILE

service mysql-server stop
mysqld_safe --init-file=/root/mysql-init.txt
service mysql-server start



#php.ini
cp /usr/local/etc/php.ini-development /usr/local/etc/php.ini

FILE=/usr/local/etc/php.ini
grep -q "(^(#|)extension=php_mbstring.dll)" $FILE && sed -i 's/^((#|)extension=php_mysqli.dll).*/extension=php_mbstring.dll/' $FILE|| echo "extension=php_mbstring.dll" >> $FILE
grep -q "(^(#|)extension=php_mysqli.dll)" $FILE && sed -i 's/(^(#|)extension=php_mysqli.dll).*/extension=php_mysqli.dll/' $FILE ||echo "extension=php_mysqli.dll" >> $FILE
grep -q "(^(#|)date\.timezone(\ |)\=(\ |)" $FILE && sed -i 's/(^(#|)date\.timezone(\ |)\=(\ |).*/date\.timezone\ \=\ Europe\/Berlin/' $FILE ||echo "extension=php_mysqli.dll" >> $FILE

FILE="/usr/local/www/apache24/data/test.php"
echo '<?php
phpinfo();
?>' >> $FILE

service apache24 restart
echo "Go to  http://{jail IP address}/test.php"

#rsyslog
cd /usr/ports/sysutils/rsyslog8 && make install clean BATCH=yes
ln -s /usr/local/etc/rc.d/rsyslogd /etc/rc.d/rsyslog

#mysql
#http://linux.die.net/man/1/mysql
#mysql db_name -u root -p $PASS < script.sql > output.tab

echo 'create database loganalyzer;
create database Syslog;
create database Syslog;
CREATE TABLE SystemEvents
   (
       ID int unsigned not null auto_increment primary key,
       CustomerID bigint,
       ReceivedAt datetime NULL,
       DeviceReportedTime datetime NULL,
       Facility smallint NULL,
       Priority smallint NULL,
       FromHost varchar(60) NULL,
       Message text,
       NTSeverity int NULL,
       Importance int NULL,
       EventSource varchar(60),
       EventUser varchar(60) NULL,
       EventCategory int NULL,
       EventID int NULL,
       EventBinaryData text NULL,
       MaxAvailable int NULL,
       CurrUsage int NULL,
       MinUsage int NULL,
       MaxUsage int NULL,
       InfoUnitID int NULL ,
       SysLogTag varchar(60),
       EventLogType varchar(60),
       GenericFileName VarChar(60),
       SystemID int NULL
   );
 CREATE TABLE SystemEventsProperties
   (
       ID int unsigned not null auto_increment primary key,
       SystemEventID int NULL ,
       ParamName varchar(255) NULL ,
       ParamValue text NULL
   );
 grant all privileges on Syslog.* to 'root'@'%' identified by '$PASS' with grant option
' >> script.sql 
mysql db_name -u root -p $PASS < script.sql > output.tab
#enable rsyslog
ln -s /usr/local/etc/rc.d/rsyslogd /etc/rc.d/rsyslog
#configure syslog
FILE=/usr/local/etc/rsyslog.conf
echo '
$ModLoad immark  # provides --MARK-- message capability
$ModLoad imuxsock  # provides support for local system logging
$ModLoad ommysql  # load MySQL functionality
$AllowedSender UDP, 10.47.8.0/22 # depends on your subnet obviously
# for TCP use:
module(load="imtcp") # needs to be done just once
input(type="imtcp" port="514")
# for UDP use:
module(load="imudp") # needs to be done just once
input(type="imudp" port="514")
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
$RepeatedMsgReduction on
$WorkDirectory /var/spool/rsyslog
$FileOwner root
$FileGroup wheel
$FileCreateMode 0777
$DirCreateMode 0755
$Umask 0022
$PrivDropToUser root
$PrivDropToGroup wheel
$IncludeConfig /etc/rsyslog.d/*.conf
*.*  :ommysql:127.0.0.1,Syslog,root,qazWSX
' >> $FILE

#loganalyzer
cd /usr/ports/sysutils/loganalyzer && make install clean DEFAULT_VERSIONS=php=56
ln -s /usr/local/www/loganalyzer /usr/local/www/apache24/data/loganalyzer
touch /usr/local/www/loganalyzer/config.php
chmod 777 /usr/local/www/loganalyzer/config.php

