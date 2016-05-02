#!/bin/bash

# Dependency list
bin_dependencies="curl mysql tar gzip sed date sort wc grep head tail mv cat split mkdir"

# Web Server Settings
backup_parent_dir="/var/www/scheduled/backups"
website_root_dir="/var/www/html/NAME_HERE"
site_name="NAME_HERE"

# MySQL settings
mysql_user="USERNAME"
mysql_password="PASSWORD"
mysql_host="localhost" 

# Dropbox settings
dropbox_client_name="DROPBOX_CLIENT_FOLDER_NAME"
dropbox_folder_path="/semgeeks clients/${dropbox_client_name}/Web/Backups"
dropbox_api_key="API_KEY"
max_backups="NUM_BACKUPS"  # maximum number of backups to store in dropbox folder

# Mailgun settings
mailgun_api_key="MAILGUN_SECRET_KEY"
mailgun_domain="semgeeks.com"
mailgun_url="https://api.mailgun.net/v3/${mailgun_domain}/messages"


# Die if dependencies not installed
for dep in $bin_dependencies; 
do
  which ${dep} > /dev/null

  if [ $? -ne 0 ]; 
  then
    echo -e "${dep} command not found on server. Please install and try again."
    exit -1
  fi
done



# Read MySQL password from stdin if empty
if [ -z "${mysql_password}" ]; then
  echo -n "Enter MySQL ${mysql_user} password: "
  read -s mysql_password
  echo
fi

# Check MySQL password
echo exit | mysql --host=${mysql_host} --user=${mysql_user} --password=${mysql_password} -B 2>/dev/null
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
mysql_databases=`echo 'show databases' | mysql --host=${mysql_host} --user=${mysql_user} --password=${mysql_password} -B | sed /^Database$/d`

# Backup and compress each database
for database in $mysql_databases
do
  if [ "${database}" == "information_schema" ] || [ "${database}" == "performance_schema" ] || [ "${database}"  == "mysql" ]; then
  :

  else
    echo "Creating backup of \"${database}\" database"
    mysqldump ${additional_mysqldump_params} --host=${mysql_host} --user=${mysql_user} --password=${mysql_password} ${database} | gzip > "${backup_dir}/${database}.sql.gz"
    chmod 600 "${backup_dir}/${database}.sql.gz"
  fi
done

# Backup and compress site files
tar -zcf "${backup_dir}/${site_name}_site_files.tar.gz" "${website_root_dir}"
chmod 600 "${backup_dir}/${site_name}_site_files.tar.gz"
# Compress DB and site files together
tar -zcf "${site_name}-${backup_date}.tar.gz" "${backup_dir}"

# Open session for upload
session_start_url="https://content.dropboxapi.com/2/files/upload_session/start"
header1="Authorization: Bearer ${dropbox_api_key}"
header2="Content-Type: application/octet-stream"
header3="Dropbox-API-Arg: {}"
session_id=`curl -X "POST" --header "${header1}" --header "${header2}" --header "${header3}" ${session_start_url} | sed -r -e "s/.*\"session_id\":\s\"(.+)\".*/\1/gi"`


# Split file into 150M chunks and add chunk to session
chunk_dir="pieces"
mkdir -p "${chunk_dir}"
split --bytes=150M "${site_name}-${backup_date}.tar.gz" "${chunk_dir}/chunk-"
chunks=${chunk_dir}/*

offset=0
session_append_url="https://content.dropboxapi.com/2/files/upload_session/append_v2"
response_file="response"

for chunk in ${chunks}
do

  while true;
  do
    header3="Dropbox-API-Arg: {\"cursor\":{\"session_id\":\"${session_id}\",\"offset\":${offset}}}"
    file="@${chunk}"
    curl -v -X "POST" --header "${header1}" --header "${header2}" --header "${header3}" --data-binary "${file}" ${session_append_url} > ${response_file}

    grep -q "incorrect_offset" ${response_file}
    result=$?

    if [ "${result}" -ne 0 ];
    then
      echo -n "Error in last send. Retrying..."
    else
      break
    fi

    rm -rf ${response_file}
  done

  (( offset=${offset}+`wc -c "${chunk}" | sed -r -e "s/([0-9]*)\s.*/\1/gi"` ))
done

# Close session
session_finish_url="https://content.dropboxapi.com/2/files/upload_session/finish"
header3="Dropbox-API-Arg: {\"cursor\":{\"session_id\":\"${session_id}\",\"offset\":${offset}},\"commit\":{\"path\":\"${dropbox_folder_path}/${site_name}-${backup_date}.tar.gz\"}}"
curl -v -X "POST" --header "${header1}" --header "${header2}" --header "${header3}" ${session_finish_url} > dropbox_response



# Only keep the required amounts of backups - delete the oldest
list_url="https://api.dropboxapi.com/2/files/list_folder"
header1="Authorization: Bearer ${dropbox_api_key}"
header2="Content-Type: application/json"
data="{\"path\":\"${dropbox_folder_path}\",\"recursive\":false}"
tmpFile="filenames"

# List the backups and names to a temporary folder
curl -X "POST" --header "${header1}" --header "${header2}" --data "${data}" ${list_url} | sed -r -e "s/,\s/\n/gi" | grep "name" | sed -r -e "s/\"name\":\s\"(.+)\"/\1/gi" | sort > ${tmpFile}
current_backups=`wc -l ${tmpFile} | sed -r -e "s/[^0-9]//gi"`

delete_url="https://api.dropboxapi.com/2/files/delete"
header1="Authorization: Bearer ${dropbox_api_key}"
header2="Content-Type: application/json"


# Delete the oldest backups if maximum backups allowed is exceeded
while true;
do
  if (( "${current_backups}" > "${max_backups}" ));
  then
    oldestFile=`head -1 ${tmpFile}`
    data="{\"path\":\"${dropbox_folder_path}/${oldestFile}\"}"
    curl -X "POST" --header "${header1}" --header "${header2}" --data "${data}" ${delete_url}

    tail -n +2 "${tmpFile}" > "${tmpFile}.tmp" && mv "${tmpFile}.tmp" "${tmpFile}"
    (( current_backups=${current_backups}-1 ))
  else
    break
  fi
done


# Send mail via mailgun reporting success/failure status of backup
grep -q "path_lower" dropbox_response
result=$?

if [ "${result}" -eq 0 ];
then
  backup_link=`echo "${dropbox_folder_path}" | sed -r -e "s/\s/%20/gi"`
  message_text="Backup for ${site_name} Successful. Backup visible here: https://www.dropbox.com/home${backup_link}"
else
  message_text="Backup for ${site_name} Failed. Dropbox Error Information: `cat dropbox_response`"
fi

curl -s --user "api:${mailgun_api_key}" \
    -F from="Backup Script <backups@${mailgun_domain}>" \
    -F to="MAIL_TO_ADDRESS" \
    -F subject="Backup Information For ${site_name}" \
    -F text="${message_text}" \
    ${mailgun_url}

# Cleanup
rm -rf ${tmpFile}
rm -rf ${response_file}
rm -rf ${chunk_dir}
rm -rf ${site_name}-*
rm -rf ${backup_parent_dir}/*

echo -e "Temporary files cleaned. Run 'crontab -e' to open the crontab editor and schedule future backups."

