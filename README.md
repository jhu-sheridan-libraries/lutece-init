# Introduction

This container runs a Lutece application. A Lutece application consists of a Java Web Application and a database. The container configures
the application, initializes the database if needed, and starts the application in Apache Tomcat. The database is managed separately and must be accessible to the container.

# Configuration

Configuration can be done at runtime by setting environment variables or using volumes to modify the internal file structure. 

Environment variables:
  - `DB_HOST`        (MySQL server hostname accessible to container)
  - `MYSQL_DATABASE` (Datebase to use)
  - `MYSQL_USER`     (MySQL user for database)
  - `MYSQL_PASSWORD` (Password for MySQL user)
  - `MAIL_HOST`      (Mail hostname)
  - `MAIL_PORT`      (Mail port)
  - `MAIL_USER`      (Mail user)
  - `MAIL_PASS`      (Password for mail user)
 
The MYSQL_ variables are consistent with those used by the official MySQL containers. Each one of these variables can have a _FILE appended. In that case, the variable value is read from that file. (The _FILE variables are intended to be used with docker secrets.) Both forms of the variable should not be set. Be aware that older MySQL versions do not appear to support the _FILE variables.

In addition, the container is built from the base of the official Apache Tomcat containers, https://hub.docker.com/_/tomcat, and can be configured just like them.

# Behavior

On startup the container expects a Lutece application to be available in `/data/lutece.war` and will exit if it is not present.
Lutece applications are configured by modifying files internal to the war. In order to configure the application using environment variables above, the provided was is unpacked, modified, and then deployed to
`/usr/local/tomcat/webapps/ROOT`. The application will be accessible at `http://container:8080/`.

In addition, if the configured database appears to be empty, it will be initialized. Database initialization can take two paths. If the file `/data/lutece.sql` exists, it will be loaded as is into the database. The database dump must have come from a running site. If the file does not exist, the default Lutece database intialization for a new site is run.

Due to the version of the mysql client used by the container, the mysql server must support the mysql native password plugin.

For mysql 8:
```
mysqld --default-authentication-plugin=mysql_native_password --skip-mysqlx
```


# Building images

## Make a lutece-init release to use in development

For development use we create a lutece-init image that requires the Lutece war to be provided using a volume at `/data/lutece.war`.
Make sure `data/` is empty before building.

```
docker build -t jhulibraries/lutece-init:VERSION .
```

## Make a release for a Lutece site

The Lutece site must use overlays to provide custom `db.properties` and `config.properties` which contains values that can be substituted like below. This allows the runtime configuration to work.

*db.properties:*
```
portal.url=jdbc:mysql://#DB_HOST#/#DB_NAME#?autoReconnect=true&useUnicode=yes&characterEncoding=utf8
portal.user=#DB_USER#
portal.password=#DB_PASS#
```

*config.properties:*
```
mail.server=#MAIL_HOST#
mail.server.port=#MAIL_PORT#
mail.username=#MAIL_USER#
mail.password=#MAIL_PASS#
```

Then build the Lutece site application and copy the war into `data/lutece.war`.

```
docker build --network=host -t jhulibraries/stfrancis-site:VERSION .
```