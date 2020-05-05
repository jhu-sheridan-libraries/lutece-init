FROM tomcat:9-jdk8

# Install mysql 8 client tools ant and rpl.

ENV MYSQL_DEB mysql-apt-config_0.8.13-1_all.deb
ENV MYSQL_URL https://dev.mysql.com/get/${MYSQL_DEB}

RUN apt-get update -y && apt-get dist-upgrade -y && apt-get install -y lsb-release && wget ${MYSQL_URL} && DEBIAN_FRONTEND=noninteractive apt-get install -y ./${MYSQL_DEB} && rm ${MYSQL_DEB} && apt-get update -y && apt-get install -y mysql-client ant rpl --no-install-recommends && apt-get clean

COPY data /data
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
