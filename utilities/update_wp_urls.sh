#!/bin/bash

#Instructions to use this script 
#
#chmod +x SCRIPTNAME.sh
#
#sudo ./SCRIPTNAME.sh


#Updates urls in WordPress database from development to production
echo -e "\n"
echo -e "Enter old url including the 'http://' "
read oldurl

echo -e "\n"
echo -e "Enter new url including the 'http://' "
read newurl

echo -e "\n"
echo -e "Enter database name to update: "
read dbname

echo -e "\n"
echo -e "Enter MYSQL root user password: "
read -s rootpw


# Be careful using this GUID if the site has already been live and indexed by search engines!!
sqlcommands="USE $dbname;UPDATE wp_options SET option_value = replace(option_value, '$oldurl', '$newurl') WHERE option_name = 'home' OR option_name = 'siteurl';UPDATE wp_posts SET guid = replace(guid, '$oldurl','$newurl');UPDATE wp_posts SET post_content = replace(post_content, '$oldurl', '$newurl');UPDATE wp_postmeta SET meta_value = replace(meta_value,'$oldurl','$newurl');"
mysql -u root -p$rootpw -e "$sqlcommands"
