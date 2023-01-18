#!/bin/bash

rm -rf /var/lib/mysql/*
yum remove mysql -y
yum install httpd mariadb-server -y
systemctl restart mariadb.service
systemctl enable mariadb.service
mysqladmin -u root password 'root123'
mysql -u root -proot123 -e "create database ${DB_NAME};"
mysql -u root -proot123 -e "create user '${DB_USER}'@'%' identified by '${DB_PASSWORD}';"
mysql -u root -proot123 -e "grant all privileges on ${DB_NAME}.* to '${DB_USER}'@'%'"
mysql -u root -proot123 -e "flush privileges"
