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
    server_name $wordpress;
    access_log off;
    location / {
        rewrite ^ https://\$host\$request_uri? permanent;
    }
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $wordpress;
    root /var/www/$wordpress;
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
sed -i "s|^define( 'DB_NAME', 'database_name_here' );|define( 'DB_NAME', '$dbname' );|" /var/www/"$wordpress"/wp-config.php
sed -i "s|^define( 'DB_USER', 'username_here' );|define( 'DB_USER', '$username' );|" /var/www/"$wordpress"/wp-config.php
sed -i "s|^define( 'DB_PASSWORD', 'password_here' );|define( 'DB_PASSWORD', '$userpass' );|" /var/www/"$wordpress"/wp-config.php



#Allow Nginx to write files to your WordPress website
echo "define( 'FS_METHOD', 'direct' );
/* That's all, stop editing! Happy publishing. */" >> /var/www/"$wordpress"/wp-config.php




nginx80(){

cp /etc/nginx/sites-available/$wordpress /etc/nginx/sites-available/$wordpress.bkp
systemctl stop nginx
rm /etc/nginx/sites-available/$wordpress	

cat <<EOF > /etc/nginx/sites-available/"$wordpress"
server {
listen 80;
server_name $wordpress;
root /var/www/$wordpress/;
}
EOF

#less /etc/nginx/sites-available/"$wordpress"
sleep5
nginx -t
systemctl start nginx

}


nginx443(){
	
systemctl stop nginx
rm /etc/nginx/sites-available/$wordpress


cat << EOF > /etc/nginx/sites-available/"$wordpress"
server {
    listen 80;
    listen [::]:80;
    server_name genius.qbits.in;
    access_log off;
    root /var/www/genius.qbits.in;
    location / {
        rewrite ^ https://\$host\$request_uri? permanent;
    }
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name genius.qbits.in;
    root /var/www/$wordpress;
    index index.php index.html index.htm index.nginx-debian.html;
    autoindex off;
    ssl_certificate /etc/letsencrypt/live/$wordpress/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$wordpress/privkey.pem;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location ~ \.php$ {
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
    location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
        expires max;
        log_not_found off;
    }
}

EOF

#less /etc/nginx/sites-available/"$wordpress"
sleep 5
nginx -t
systemctl start nginx

sleep 15

}





setupssl(){

					echo " Select your ssl-cert configuration"
									
									select ssl_conf in Self_Signed_Cert certbot_letsencrypt "exit"

								do
									echo "You have opted : $REPLY: $ssl_conf"
																
											if [[ $REPLY == "1" ]]; then

													read -r -p "rsa length(4096 recommended): " rsa_value
													#read -r -p "public_certificate_path: " public_certificate_path
													public_certificate_path=/etc/ssl/certs/lemp.pem
													#read -r -p "private_key_path: " private_key_path
													private_key_path=/etc/ssl/private/lemp.key

													read -r -p "certificate_duration_in_days: " certificate_duration_in_days
													read -r -p "country_code: " country_code
													read -r -p "organization_name: " organization_name
													read -r -p "organizational_unit " organizational_unit
													read -r -p "common_name(FQND or IP): " common_name

													sed -i "s|^/etc/letsencrypt/live/$wordpress/fullchain.pem;|/etc/ssl/certs/lemp.pem;|" /etc/nginx/sites-available/"$wordpress"														
													sed -i "s|^/etc/letsencrypt/live/$wordpress/privkey.pem|/etc/ssl/private/lemp.key;|" /etc/nginx/sites-available/"$wordpress"
																				
													echo "generating and signing certificates"
													openssl req -x509 -newkey rsa:"$rsa_value" -nodes -out $public_certificate_path -keyout $private_key_path -days "$certificate_duration_in_days" -subj "/C=$country_code/O=$organization_name/OU=$organizational_unit/CN=$common_name"

													sudo systemctl reload nginx
													echo "Everything done Please go to your website"
													
												
												elif [[ $REPLY == "2" ]]; then

														sudo snap install core; sudo snap refresh core
														sudo apt remove certbot -y
														sudo snap install --classic certbot
														sudo ln -s /snap/bin/certbot /usr/bin/certbot

														cp /etc/nginx/sites-available/$wordpress /etc/nginx/sites-available/$wordpress.bkp
														systemctl stop nginx
														
														read -r -p "common_name(FQND or IP): " common_name

														read -r -p "Enter your email: " email
														
														#edit ngnx serverblock for auto-certbot-challenge
														nginx80
																												
														sudo certbot certonly --webroot --webroot-path /var/www/"$wordpress" -m "$email" -d "$wordpress" --agree-tos -n
														
														#rewrite nginx directive
														nginx443
																										

												elif [[ $REPLY == "3" ]]; then
														echo "setupSSL to enable access to website"
														exit		

												else echo "You need to setup certs to access your website"
															setupssl


												fi
								done

		}

setupssl

