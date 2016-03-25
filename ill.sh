#!/bin/bash

#Wrapper to run full install and config.


#Make sure everything is executable in the current directory
sudo chmod +x *.sh


#Run all scripts
sudo ./installs.sh
sudo ./setup.sh
sudo ./security.sh
sudo ./cleanup.sh