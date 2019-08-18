#!/bin/bash

# sleep until instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# install php and mysql packages
yum -y install httpd php php-mysql php-gd php-xml mariadb-server mariadb php-mbstring

# make sure mariadb is started
systemctl start mariadb

# create database and user
mysql -u root -e "CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'wiki';"
mysql -u root -e "CREATE DATABASE wikidb;"
mysql -u root -e "GRANT ALL PRIVILEGES ON wikidb.* TO 'wiki'@'localhost';"
mysql -u root -e "GRANT ALL PRIVILEGES ON wikidb.* TO 'wiki'@'l0.0.1.35';"
mysql -u root -e "GRANT ALL PRIVILEGES ON wikidb.* TO 'wiki'@'10.0.1.36';"
mysql -u root -e "FLUSH PRIVILEGES;"
systemctl enable mariadb
