#!/bin/bash

backup_parent_dir="/var/www/scheduled/backups"
website_root_dir="/var/www/html/NAME_HERE"
site_name="NAME_HERE"
dropbox_client_name="DROPBOX_CLIENT_FOLDER_NAME"
dropbox_folder_path="/semgeeks clients/${dropbox_client_name}/Web/Backups"
dropbox_api_key="API_KEY"
max_backups="NUM_BACKUPS"

# MySQL settings
mysql_user="USERNAME"
mysql_password="PASSWORD"

# Read MySQL password from stdin if empty
if [ -z "${mysql_password}" ]; then
  echo -n "Enter MySQL ${mysql_user} password: "
  read -s mysql_password
  echo
fi

# Check MySQL password
echo exit | mysql --user=${mysql_user} --password=${mysql_password} -B 2>/dev/null
if [ "$?" -gt 0 ]; then
  echo "MySQL ${mysql_user} password incorrect"
  exit 1
else
  echo "MySQL ${mysql_user} password correct."
fi

# Create backup directory and set permissions
backup_date=`date +%Y_%m_%d_%H_%M`
backup_dir="${backup_parent_dir}/${backup_date}"
echo "Backup directory: ${backup_dir}"
mkdir -p "${backup_dir}"
chmod 700 "${backup_dir}"

# Get MySQL databases
mysql_databases=`echo 'show databases' | mysql --user=${mysql_user} --password=${mysql_password} -B | sed /^Database$/d`

# Backup and compress each database
for database in $mysql_databases
do
  if [ "${database}" == "information_schema" ] || [ "${database}" == "performance_schema" ] || [ "${database}"  == "mysql" ]; then
  :

  else
  echo "Creating backup of \"${database}\" database"
  mysqldump ${additional_mysqldump_params} --user=${mysql_user} --password=${mysql_password} ${database} | gzip > "${backup_dir}/${database}.sql.gz"
  chmod 600 "${backup_dir}/${database}.sql.gz"
fi
done

# Backup and compress site files
tar -zcvf "${backup_dir}/${site_name}_site_files.tar.gz" "${website_root_dir}"
chmod 600 "${backup_dir}/${site_name}_site_files.tar.gz"
# Compress DB and site files
tar -zcvf "${site_name}-${backup_date}.tar.gz" "${backup_dir}"

# Open session for upload
session_start_url="https://content.dropboxapi.com/2/files/upload_session/start"
header1="Authorization: Bearer ${dropbox_api_key}"
header2="Content-Type: application/octet-stream"
header3="Dropbox-API-Arg: {}"
sessionID=`curl -v -X "POST" --header "${header1}" --header "${header2}" --header "${header3}" ${session_start_url} | sed -r -e "s/.*\"session_id\":\s\"(.+)\".*/\1/gi"`

# Split file into 150M chunks and add chunk to session
mkdir -p pieces
split --bytes=150M "${site_name}-${backup_date}.tar.gz" "pieces/chunk-"
offset=0
chunks=pieces/*
session_append_url="https://content.dropboxapi.com/2/files/upload_session/append_v2"

for chunk in ${chunks}
do
  header3="Dropbox-API-Arg: {\"cursor\":{\"session_id\":\"${sessionID}\",\"offset\":${offset}}}"
  file="@${chunk}"
  curl -v -X "POST" --header "${header1}" --header "${header2}" --header "${header3}" --data-binary "${file}" ${session_append_url}
  (( offset=${offset}+`wc -c "${chunk}" | sed -r -e "s/([0-9]*)\s.*/\1/gi"` ))
done

# Close session
session_finish_url="https://content.dropboxapi.com/2/files/upload_session/finish"
header3="Dropbox-API-Arg: {\"cursor\":{\"session_id\":\"${sessionID}\",\"offset\":${offset}},\"commit\":{\"path\":\"${dropbox_folder_path}/${site_name}-${backup_date}.tar.gz\"}}"
curl -v -X "POST" --header "${header1}" --header "${header2}" --header "${header3}" ${session_finish_url}


# Only keep the required amounts of backups - delete the oldest
listURL="https://api.dropboxapi.com/2/files/list_folder"
header1="Authorization: Bearer ${dropbox_api_key}"
header2="Content-Type: application/json"
data="{\"path\":\"${dropbox_folder_path}\",\"recursive\":false}"
tmpFile="filenames"

# List the backups and names to a temporary folder
curl -X "POST" --header "${header1}" --header "${header2}" --data "${data}" ${listURL} | sed -r -e "s/,\s/\n/gi" | grep "name" | sed -r -e "s/\"name\":\s\"(.+)\"/\1/gi" | sort > ${tmpFile}
current_backups=`wc -l ${tmpFile} | sed -r -e "s/[^0-9]//gi"`

deleteURL="https://api.dropboxapi.com/2/files/delete"
header1="Authorization: Bearer ${dropbox_api_key}"
header2="Content-Type: application/json"

# Delete the oldest backups if maximum backups allowed is exceeded
while true;
do
  if (( "${current_backups}" > "${max_backups}" ));
  then
    oldestFile=`head -1 ${tmpFile}`
    data="{\"path\":\"${dropbox_folder_path}/${oldestFile}\"}"
    curl -X "POST" --header "${header1}" --header "${header2}" --data "${data}" ${deleteURL} >/dev/null 2>&1

    tail -n +2 "${tmpFile}" > "${tmpFile}.tmp" && mv "${tmpFile}.tmp" "${tmpFile}"
    (( current_backups=${current_backups}-1 ))
  else
    break
  fi
done

# Cleanup
rm -rf ${tmpFile}
rm -rf pieces
rm -rf ${site_name}-*
rm -rf ${backup_dir}