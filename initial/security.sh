#!/bin/bash

#Instructions to use this script 
#
#chmod +x SCRIPTNAME.sh
#
#sudo ./SCRIPTNAME.sh


#Install fail2ban
sudo apt-get update
sudo apt-get -y install fail2ban


#Copy and configure the local jail file
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

#Config defaults (fixing later)
defretry=10
deffind=600
defban=3600

#sed -i -r -e "s/\[DEFAULT\].*?(bantime = ).+/\1${defban}/i"


#Configure default Firewall
#    Drop all connections except for traffic going through ports 22, 80 or 3306
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 3306 -j ACCEPT
sudo iptables -A INPUT -j DROP

#Install persistent IPTables package to save current configuration and auto-load on server restart
sudo apt-get -y install iptables-persistent
