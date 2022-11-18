#!/bin/bash

apt update

#setup nginx web-server
sudo apt install nginx -y
sudo systemctl status nginx
#setup database server and client
sudo apt install mariadb-server mariadb-client -y
sudo systemctl status mariadb
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo mysql_secure_installation
#setup-php
sudo apt install php8.1 php8.1-fpm php8.1-mysql php-common php8.1-cli php8.1-common php8.1-opcache php8.1-readline php8.1-mbstring php8.1-xml php8.1-gd php8.1-curl -y
sudo systemctl start php8.1-fpm
sudo systemctl enable php8.1-fpm
sudo systemctl status php8.1-fpm

#sed -i 's|^upload_max_filesize = *;|upload_max_filesize = 32M;|' /etc/php/8.1/fpm/php.ini
sed -i 's|^upload_max_filesize\s=\s2M|upload_max_filesize = 32M|g' post_max_size = 8M
sed -i 's|^post_max_size\s=\s8M|post_max_size = 48M|g' /etc/php/8.1/fpm/php.ini
sed -i 's|^memory_limit = */memory_limit = 256M|g' /etc/php/8.1/fpm/php.ini
sed -i 's|^max_execution_time\s=\s30|max_execution_time = 600|g' /etc/php/8.1/fpm/php.ini
sed -i 's|^;max_input_vars\s=\s1000 = *|max_input_vars = 3000|g' /etc/php/8.1/fpm/php.ini
sed -i 's|^max_input_time\s=\s60|max_input_time = 1000|g' /etc/php/8.1/fpm/php.ini

sudo systemctl restart php8.1-fpm

#configure Nginx virtual Host

cat <<EOF > /etc/nginx/sites-enabled/default
server {
listen 80;

root /var/www/html;

index index.php index.nginx-debian.html;

server_name example.com www.example.com;

location / {
try_files \$uri \$uri/ =404;
}

location ~ \.php$ {
include snippets/fastcgi-php.conf;
fastcgi_pass unix:/run/php/php8.1-fpm.sock;
}


}
EOF





nginx -t
sudo systemctl restart nginx php8.1-fpm

echo "LEMP has been insalled successfully"

read -r -p "Do you want to setup wordpress now: [y/N]?" permission

if [[ "$permission" == Y || "$permission" == y ]]; then
sudo chmod +x 2_dbsetup.sh
sudo ./2_dbsetup.sh
else echo "Setup wordpress as and when required later"
fi
