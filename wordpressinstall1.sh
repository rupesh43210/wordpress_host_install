#!/bin/bash

apt update

#setup nginx web-server
sudo apt install nginx
sudo systemctl status nginx
#setup database server and client
sudo apt install mariadb-server mariadb-client -y
sudo systemctl status mariadb
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo mysql_secure_installation
#setup-php
sudo apt install php8.1 php8.1-fpm php8.1-mysql php-common php8.1-cli php8.1-common php8.1-opcache php8.1-readline php8.1-mbstring php8.1-xml php8.1-gd php8.1-curl
sudo systemctl start php8.1-fpm
sudo systemctl enable php8.1-fpm
sudo systemctl status php8.1-fpm

sed -i 's/^upload_max_filesize = */upload_max_filesize = 32M' /etc/php/8.1/fpm/php.ini
sed -i 's/^post_max_size = */post_max_size = 48M' /etc/php/8.1/fpm/php.ini
sed -i 's/^memory_limit = */memory_limit = 256M' /etc/php/8.1/fpm/php.ini
sed -i 's/^max_execution_time  =*/max_execution_time = 600' /etc/php/8.1/fpm/php.ini
sed -i 's/^max_input_vars = */max_input_vars = 3000' /etc/php/8.1/fpm/php.ini
sed -i 's/^max_input_time = */max_input_time = 1000' /etc/php/8.1/fpm/php.ini

sudo systemctl restart php8.1-fpm
