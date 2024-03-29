#!/bin/bash

# sleep until instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# install php and mysql packages
yum -y install httpd php php-mysql php-gd php-xml mariadb-server mariadb php-mbstring

systemctl enable httpd

# download mediawiki package
yum -y install wget
wget https://releases.wikimedia.org/mediawiki/1.23/mediawiki-core-1.23.17.tar.gz
tar -zxf /home/centos/mediawiki-core-1.23.17.tar.gz -C /var/www/
ln -s /var/www/mediawiki-1.23.17 /var/www/mediawiki
pub_ip=`curl -s ifconfig.me`
sed -i "s#localhost#$pub_ip#g" /home/centos/LocalSettings.php
cp /home/centos/LocalSettings.php /var/www/mediawiki/
chown -R apache:apache /var/www/mediawiki
sed -i "s#/var/www/html#/var/www/mediawiki#g" /etc/httpd/conf/httpd.conf
systemctl restart httpd.service
