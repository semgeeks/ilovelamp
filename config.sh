#!/bin/bash

#Instructions to use this script 
#
#chmod +x SCRIPTNAME.sh
#
#sudo ./SCRIPTNAME.sh



#Enable Apache and php5 modules
sudo php5enmod mcrypt
sudo a2enmod rewrite


#Permissions assignments on /var/www/html
WEBROOT=/var/www/html
sudo chown www-data:www-data $WEBROOT -R
sudo chmod g+s $WEBROOT
sudo chmod o-wrx $WEBROOT -R


#Php.ini memory limit increases
echo -e "\n"
echo -e "Enter memory limit for php.ini (e.g. 32M): "

read limit

sed -i -e "s/(upload_max_file_size=).+/$1${limit}/gi" /etc/php5/apache2/php.ini
sed -i -e "s/(post_max_size=).+/$1${limit}/gi" /etc/php5/apache2/php.ini
sed -i -e "s/(memory_limit=).+/$1${limit}/gi" /etc/php5/apache2/php.ini

