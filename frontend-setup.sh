#!/bin/bash

yum install httpd -y
amazon-linux-extras install php7.4 -y
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -pr wordpress/* /var/www/html/
chown -R apache. /var/www/html/
cp -pr /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i 's/localhost/${DB_HOST}/g' /var/www/html/wp-config.php
sed -i 's/database_name_here/${DB_NAME}/g' /var/www/html/wp-config.php
sed -i 's/username_here/${DB_USER}/g' /var/www/html/wp-config.php
sed -i 's/password_here/${DB_PASSWORD}/g' /var/www/html/wp-config.php
systemctl start httpd.service
systemctl enable httpd.service
