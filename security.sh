#!/bin/bash

#Instructions to use this script 
#
#chmod +x SCRIPTNAME.sh
#
#sudo ./SCRIPTNAME.sh


#Install fail2ban
sudo apt-get install fail2ban


#Copy and configure the local jail file
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

#Config defaults (fixing later)
defretry=10
deffind=600
defban=3600


#Configure default Firewall
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 3306 -j ACCEPT
sudo iptables -A INPUT -j DROP