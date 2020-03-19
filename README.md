# Introduction

The lutece-init container initializes a MySQL container for a Lutece site.

# Configuration

Variables to configure MySQL docker container.
See [https://github.com/docker-library/docs/tree/master/mysql] for more info.

  - `MYSQL_DATABASE` (Datebase used. Created by MySQL container.)
  - `MYSQL_USER`     (MySQL user for database.)
  - `MYSQL_PASSWORD` (Passwords for MySQL user)
  - `MYSQL_ROOT_PASSWORD` (Password for MySQL root user.)

Each one of these variables can have a _FILE appended. In that case, the variable value is read from that file. (The _FILE variables are intended to be used with docker secrets.) Both forms of the variable should not be set. Be aware that older MySQL versions do not appear to support the _FILE variables.

Variables to configure lutece-init container.
  - `DB_HOST` (MySQL host accessible to container.)

A complicating factor is that lutece can only be configured by modifying files internal to the war.

# Run 

A Lutece site war must be made available to lutece-init as `/data/lutece.war`. A MySQL container must be started configured using the variables above.

The lutece-init container will configure lutece.war by producing a modified version of the war as `/webapps/lutece.war`. (Another container is expected to deploy the modified war.) The modified war is only updated if the lutece.war is newer. The lutece-init container will create and intialize the database if needed and exit.
Database initialization can take two paths. If the file `/data/lutece.sql` exists, it will be loaded as is into the database. The database dump must have come from a running site. If the file does not exist, the default Lutece database intialization for a new site is run.
