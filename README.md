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
**!IMPORTANT**
Read Usage notes before attempting to run this script.

This script can be run independently and also set to run with a cronjob. It performs a sqldump of all databases except for the default ones such as information_schema, etc, and then compresses them all into a single gzipped file. After this completes, the specified site-file directory will be tar'd and then sent through gzip to produce a .tar.gz file. The compressed versions of the databases and site files are then compressed together to produce a single backup file. This backup file is then sent to dropbox, and an email is sent to a specified recipient containing the results of the dropbox transport. A maximum number of backups to be kept in dropbox can be set - the oldest will be deleted after receiving the newest backup that exceeds this quota. 

**Usage Notes:**
Open site_backup.sh with a text editor to fill in the necessary variable values before operation. Mandatory variables and value requirements are detailed below.

*backup_parent_dir* - Directory in which to store backups locally on the server once complete. Note that in order for this to function as expected, the command `rm -rf ${backup_parent_dir}/*` must be removed from the bottom of the script in the cleanup area. It is a part of the cleanup process due to the generally limited storage space on a VPS. Check this directory if disk space becomes low over time to ensure the cleanup was successful.

*website_root_dir* - Full path to the root directory of the website to be backed up.

*site_name* - The name of the root directory of the website.

*MySQL Credentials* - It is recommended to enter credentials for the root MySQL user if there are multiple databases being backed up to avoid any permissions related issues, otherwise the credentials for the user with full permission to the corresponding database is sufficient. The MySQL server generally does not need to be changed from localhost unless running on a shared host where the database is likely hosted elsewhere. Look to the hosting provider to obtain the domain for the MySQL server if necessary.

*Dropbox Settings* - The dropbox folder path is necessary and if it does not already exist on dropbox, it will be created at the time of upload. The API key can be obtained [here](https://dropbox.github.io/dropbox-api-v2-explorer/#auth_token/revoke) - log in to dropbox if not already logged in and click "Get Token." The token returned is the API key for this script. Max_backups can be changed at any time. Only the _n_ most recent backups will be kept, all others will be deleted until the maximum allowed has been reached.

*Mailgun Settings* - The mailgun API key can be obtained after signing up for a mailgun account; it begins with "key-". The mailto is the email address in which to send the results of the dropbox upload, and the mailgundomain is obtained after registering a domain in the mailgun account. 

### update_wp_urls.sh
Updates URLs in a specified database from an old URL to a new URL. Useful after moving a WordPress site from a development/staging/live environment to another environment. This updates the wp_options, wp_posts (guid and posts), and wp_postmeta tables.
