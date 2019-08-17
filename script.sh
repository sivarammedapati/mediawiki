#!/bin/bash

# sleep until instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# install php and mysql packages
yum -y update
yum -y install httpd php php-mysql php-gd php-xml mariadb-server mariadb php-mbstring

# make sure mariadb is started
systemctl start mariadb

# create database and user
mysql -u root -e "CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'wiki';"
mysql -u root -e "CREATE DATABASE wikidb;"
mysql -u root -e "GRANT ALL PRIVILEGES ON wikidb.* TO 'wiki'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"
systemctl enable mariadb
systemctl enable httpd

# download mediawiki package
yum -y install wget
wget https://releases.wikimedia.org/mediawiki/1.23/mediawiki-core-1.23.17.tar.gz
tar -zxf /home/centos/mediawiki-core-1.23.17.tar.gz -C /var/www/
ln -s /var/www/mediawiki-1.23.17 /var/www/mediawiki
chown -R apache:apache /var/www/mediawiki
