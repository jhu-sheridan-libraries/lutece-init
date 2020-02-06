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
	echo "Initializing database..."

	cd ${modifiedwardir}/WEB-INF/sql && ant

	if [ -f /lutece.sql ]
	then
	    echo "Loading /lutece.sql"
	    mysql -u ${DB_USER} -p${DB_PASS} -h ${DB_HOST} ${DB_NAME} < /lutece.sql
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

get_file_value ${MYSQL_ROOT_PASSWORD_FILE} ${MYSQL_ROOT_PASSWORD}
DB_ROOT_PASS=${fileValue}

# Lutece war must be modified before being deployed with secret config values.
# Only modify and deploy war if needed.

sourcewar=/lutece.war
deploywar=/webapps/ROOT.war
deployedwardir=/webapps/ROOT
extractdir=/lutece
dbconfigfile=${extractdir}/WEB-INF/conf/db.properties

# Replace strings in a given file
# Usage: rplfile KEY VALUE FILE
rplfile() {
    # Set LANG to work around rpl bug
    LANG=en_US.UTF-8 rpl -q "$1" "$2" "$3" > /dev/null 2>&1
}

if [ ! -f ${deploywar} ] || [ ${sourcewar} -nt ${deploywar} ]
then
    echo "Modifying war"

    rm -f ${deploywar}
    unzip -q ${sourcewar} -d ${extractdir}

    rplfile "#DB_NAME#" "${DB_NAME}" ${dbconfigfile}
    rplfile "#DB_USER#" "${DB_USER}" ${dbconfigfile}
    rplfile "#DB_PASS#" "${DB_PASS}" ${dbconfigfile}
    rplfile "#DB_HOST#" "${DB_HOST}" ${dbconfigfile}

    init_db ${extractdir}

    cd ${extractdir} && jar cf /tmp.war *

    echo "Deploying modified war"
    mv /tmp.war ${deploywar}
else
    echo "No war modification needed"
    init_db ${deploywardir}
fi
