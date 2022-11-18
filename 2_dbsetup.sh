#!/bin/bash

# If /root/.my.cnf exists then it won't ask for root password
if [ -f /root/.my.cnf ]; then
	echo "Enter database name!- to create new database"
	read dbname
    
	echo "Creating new MySQL database..."
	mysql -e "CREATE DATABASE ${dbname} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	echo "Database successfully created!"
	
	echo "Enter database user!-create new user"
	read username
    
	echo "Enter the PASSWORD for database user!- password of new user"
	echo "Note: password will be hidden when typing"
	read -s userpass
    
	echo "Creating new user..."
	mysql -e "CREATE USER ${username}@localhost IDENTIFIED BY '${userpass}';"
	echo "User successfully created!"

	echo "Granting ALL privileges on ${dbname} to ${username}!"
	mysql -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${username}'@'localhost';"
	mysql -e "FLUSH PRIVILEGES;"
	echo "You're good now :)"
	exit
	
# If /root/.my.cnf doesn't exist then it'll ask for root password	
else
	echo "Please enter root user MySQL password!"
	echo "Note: password will be hidden when typing"
	read -s rootpasswd
    
	echo "Enter database name!"
	read dbname
    
	echo "Creating new MySQL database..."
	mysql -uroot -p${rootpasswd} -e "CREATE DATABASE ${dbname} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	echo "Database successfully created!"
    
	echo "Enter database user!"
	read username
    
	echo "Enter the PASSWORD for database user!"
	echo "Note: password will be hidden when typing"
	read -s userpass
    
	echo "Creating new user..."
	mysql -uroot -p${rootpasswd} -e "CREATE USER ${username}@localhost IDENTIFIED BY '${userpass}';"
	echo "User successfully created!"
	
	echo "Granting ALL privileges on ${dbname} to ${username}!"
	mysql -uroot -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${username}'@'localhost';"
	mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"
	echo "You're good now :)"
	exit
fi

#Setup prerequisites for wordpress
sudo apt install php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip php-imagick -y

sudo systemctl restart php8.1-fpm.service
sudo systemctl status php* | grep fpm.service
sudo systemctl status nginx

read -r -p 'Enter FQDN or IP of your website: ' wordpress

sudo mkdir /var/www/"$wordpress"

cat <<EOF >/etc/nginx/sites-available/"$wordpress"
server {
    listen 80;
    listen [::]:80;
    server_name "$wordpress";
    access_log off;
    location / {
        rewrite ^ https://\$host\$request_uri? permanent;
    }
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name "$wordpress";
    root /var/www/"$wordpress";
    index index.php index.html index.htm index.nginx-debian.html;
    autoindex off;
    ssl_certificate /etc/ssl/certs/lemp.pem;
    ssl_certificate_key /etc/ssl/private/lemp.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location ~ \\.php$ {
         include snippets/fastcgi-php.conf;
         fastcgi_pass unix:/var/run/php/php-fpm.sock;
         fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
         include fastcgi_params;
    }

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }
    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt { log_not_found off; access_log off; allow all; }
    location ~* \\.(css|gif|ico|jpeg|jpg|js|png)$ {
        expires max;
        log_not_found off;
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/"$wordpress" /etc/nginx/sites-enabled
sudo ls -l /etc/nginx/sites-enabled
sudo unlink /etc/nginx/sites-enabled/default
sudo ls -l /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl reload nginx


cat <<EOF >/var/www/"$wordpress"/test.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Wordpress on LEMP Test Page</title>
</head>
<body>
    <h1>Test Page for WordPress Nginx Configuration</h1>
</body>
</html>
EOF





#Downloading Wordpress and setting its configuration
cd /tmp || exit
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
ls /tmp/wordpress
cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php
sudo cp -a /tmp/wordpress/. /var/www/"$wordpress"
sudo ls -l /var/www/"$wordpress"
sudo chown -R www-data:www-data /var/www/"$wordpress"



#setup credentials for database connection
sed -i 's|^define( 'DB_NAME', 'wordpress' );|define( 'DB_NAME', '"$dbname"' );' /var/www/"$wordpress"/wp-config.php
sed -i 's|^define( 'DB_USER', 'wp_user' );|define( 'DB_USER', '"$username"' );' /var/www/"$wordpress"/wp-config.php
sed -i 's|^define( 'DB_PASSWORD', 'password' );|define( 'DB_PASSWORD', '"$userpass"' );' /var/www/"$wordpress"/wp-config.php


#Allow Nginx to write files to your WordPress website
echo "define( 'FS_METHOD', 'direct' );
/* That's all, stop editing! Happy publishing. */" >> /var/www/"$wordpress"/wp-config.php





echo "Everything done Please go to your website"
