#! /bin/bash

# If file exists, set fileValue to contents. Otherwise set fileValue to default value.
# Usage: get_file_value FILE DEFAULT_VALUE
fileValue=""
get_file_value() {
    local file="$1"    

    fileValue="$2"

    if [ -e "${file}" ]
    then
	fileValue=$(cat "${file}")
    fi
}

# If needed, init MySQL db
# Usage: init_db modified_war_dir
init_db() {
    modifiedwardir="$1"

    echo "Waiting for MySQL server"

    while ! mysqladmin ping -h${DB_HOST} --silent; do
	sleep 1
    done

    echo "Found MySQL server"

    TABLE="core_datastore"

    echo "Checking if table <$TABLE> exists ..."

    mysql -u ${DB_USER} -p${DB_PASS} -h ${DB_HOST} -e "desc $TABLE" ${DB_NAME} > /dev/null 2>&1

    if [ $? -eq 0 ]
    then
	echo "Database already initialized"
    else
	echo "Database is empty"

	if [ -f ${sqlinitfile} ]
	then
	    echo "Loading database from dump"
	    mysql -u ${DB_USER} -p${DB_PASS} -h ${DB_HOST} ${DB_NAME} < ${sqlinitfile}
	else
	    echo "Initiliazing new site database"	    
	    cd ${modifiedwardir}/WEB-INF/sql && ant	    
	fi
    fi
}

# Grab configuration values possibly stored in files

get_file_value ${MYSQL_DATABASE_FILE} ${MYSQL_DATABASE}
DB_NAME=${fileValue}

get_file_value ${MYSQL_USER_FILE} ${MYSQL_USER}
DB_USER=${fileValue}

get_file_value ${MYSQL_PASSWORD_FILE} ${MYSQL_PASSWORD}
DB_PASS=${fileValue}

get_file_value ${MAIL_HOST_FILE} ${MAIL_HOST}
MAIL_HOST=${fileValue}

get_file_value ${MAIL_PORT_FILE} ${MAIL_PORT}
MAIL_PORT=${fileValue}

get_file_value ${MAIL_USER_FILE} ${MAIL_USER}
MAIL_USER=${fileValue}

get_file_value ${MAIL_PASS_FILE} ${MAIL_PASS}
MAIL_PASS=${fileValue}

# Lutece war must be modified before being deployed with secret config values.
# Only modify and deploy war if needed.

sourcewar=/data/lutece.war
sqlinitfile=/data/lutece.sql
deploywar=/usr/local/tomcat/webapps/ROOT.war
deploywardir=/usr/local/tomcat/webapps/ROOT
extractdir=/lutece
dbconfigfile=${extractdir}/WEB-INF/conf/db.properties
configfile=${extractdir}/WEB-INF/conf/config.properties

# Replace strings in a given file
# Usage: rplfile KEY VALUE FILE
rplfile() {
    # Set LANG to work around rpl bug
    LANG=en_US.UTF-8 rpl -q "$1" "$2" "$3" > /dev/null 2>&1
}

if [ ! -f ${sourcewar} ]
then
    echo "Error: No source war ${sourcewar} found."
    exit 1
fi
   
if [ ! -f ${deploywar} ] || [ ${sourcewar} -nt ${deploywar} ]
then
    echo "Modifying source war to create deployment war"

    rm -f ${deploywar}
    unzip -q ${sourcewar} -d ${extractdir}

    rplfile "#DB_NAME#" "${DB_NAME}" ${dbconfigfile}
    rplfile "#DB_USER#" "${DB_USER}" ${dbconfigfile}
    rplfile "#DB_PASS#" "${DB_PASS}" ${dbconfigfile}
    rplfile "#DB_HOST#" "${DB_HOST}" ${dbconfigfile}

    rplfile "#MAIL_HOST#" "${MAIL_HOST}" ${configfile}
    rplfile "#MAIL_PORT#" "${MAIL_PORT}" ${configfile}
    rplfile "#MAIL_USER#" "${MAIL_USER}" ${configfile}
    rplfile "#MAIL_PASS#" "${MAIL_PASS}" ${configfile}

    init_db ${extractdir}

    cd ${extractdir} && jar cf /tmp.war *

    echo "Deploying modified war"
    mv /tmp.war ${deploywar}
else
    echo "No changes to deployed war needed."
    init_db ${deploywardir}
fi


# Start tomcat

catalina.sh run
