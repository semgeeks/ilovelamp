#!/bin/bash

#Instructions to use this script 
#
#chmod +x SCRIPTNAME.sh
#
#sudo ./SCRIPTNAME.sh



#Enable Apache and php5 modules
sudo php5enmod mcrypt
sudo a2enmod rewrite


#Obtain site name for directory creation and configuration
echo -e "\n"
echo -e "Enter site directory name (hyphenate words, do not use spaces): "
read sitename


#Permissions assignments on /var/www/$sitename
WEBROOT=/var/www/$sitename
sudo mkdir $WEBROOT
sudo chown www-data:www-data $WEBROOT -R
sudo chmod g+s $WEBROOT
sudo chmod o-wrx $WEBROOT -R


#Create virtualhost file
echo "<VirtualHost *:80>
        DocumentRoot /var/www/$sitename/
        ServerName $sitename
        <Directory /var/www/$sitename/>
                Options +Indexes +FollowSymLinks +MultiViews +Includes
                AllowOverride All
                Order allow,deny
                allow from all
        </Directory>
</VirtualHost>" > /etc/apache2/sites-available/$sitename.conf


#Add host to hosts file
echo 127.0.0.1 $sitename >> /etc/hosts


#Enable the new site
sudo a2ensite $sitename


#Php.ini memory limit increases
echo -e "\n"
echo -e "Enter memory limit for php.ini (e.g. 32M): "
read limit

sed -i -e "s/(upload_max_file_size=).+/$1${limit}/gi" /etc/php5/apache2/php.ini
sed -i -e "s/(post_max_size=).+/$1${limit}/gi" /etc/php5/apache2/php.ini
sed -i -e "s/(memory_limit=).+/$1${limit}/gi" /etc/php5/apache2/php.ini


#Create site db and new user
echo -e "\n"
echo -e "Enter MYSQL database name: "
read dbname

echo -e "\n"
echo -e "Enter new MYSQL user name: "
read dbuser

echo -e "\n"
echo -e "Enter new MYSQL user's password: "
read -s dbpw

rootpw=$(head -n 1 pw.tmp) #Read in mysql root password from temporary file created in installs.sh

sqlcommands="CREATE DATABASE IF NOT EXISTS $dbname; GRANT ALL ON $dbname.* TO $dbuser@localhost IDENTIFIED BY '$dbpw'; FLUSH PRIVILEGES;"
mysql -u root -p $rootpw -e "$sqlcommands"


#Remove temporary files
sudo rm -rf *.tmp


#Restart servers to read in new configurations
sudo service apache2 restart && service mysql restart > /dev/null