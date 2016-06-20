# ilovelamp
*AMP stack install and basic config

Do you really love LAMP? Or are you just looking at repositories and saying you love them?

## Notes
It is not recommended to keep this repository in a publicly accessible directory on the target server. For best results, run as root user or with root-level access. Currently assumes a Debian-based Linux distribution but may be expanded in the future to support Red Hat-based distributions.


# Initial
### ill.sh
This is the primary wrapper script to execute all of the specified scripts in the "Initial" folder. To execute, run `chmod +x ill.sh` or assign appropriate execution permissions to the user. If scripts are added/removed, they must be appropriately adjusted in this file unless being run solely on their own.

### installs.sh
After running the preliminary installs, the script prompts to create the MySQL root user's password. Pay close attention to what is input as typed characters will not be shown on screen. Script then writes password to temporary file for use in other scripts. DELETE pw.tmp IF THIS SCRIPT IS BEING RUN BY ITSELF WITHOUT CLEANUP!

Core Packages installed (latest stable versions unless otherwise mentioned):
- Apache2
- php5 and various extensions
- MySQL server and client
- cURL
- Composer
- NodeJS 5.x (npm included in installation)
- Bower
- Gulp


### setup.sh
Assumes package dependencies have been installed by installs.sh. When prompted for the following information, see the associated requirements:

- Site Directory Name:
  - Use the website's current or intended domain name. This information will get fed into the 'ServerName' field in the next step when creating the new VirtualHost.
- Php.ini limits
  - Note the variables shown will all be changed to the same value and must have a trailing M or G depending on the value given. If "32M" was supplied, upload_max_filesize, post_max_size, memory_limit will all be changed to 32M simultaneously. For websites requiring video uploads or large files, a larger limit may be necessary. Recommended to set at at least 8M as the default is 2M and typically needs to be raised.
- Database Information
  - The credentials created here are to be used for the operation of the website. The user created for this database will only be assigned privileges to this database.

### security.sh
Basic Security Software Installed:
- fail2ban
  - Default configuration copied to the local jail file. Use a text editor and open "/etc/fail2ban/jail.local" to make any changes.
- iptables-persistent
  - When iptables-persistent is installed, it prompts to save the current configuration for ipv4 and ipv6 to a file for reuse in the event the server is restarted. Before installation, the firewall is set to only allow traffic to the server on tcp ports 80 (HTTP), 443 (HTTPS), 22 (SSH/SFTP), and 3306 (MySQL); all other traffic is dropped.


### cleanup.sh
Removes any .tmp files that were used and restarts the Apache and MySQL services.

# Utilities
### site_backup.sh

### update_wp_urls.sh
