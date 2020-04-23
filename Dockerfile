FROM tomcat:9

RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y default-mysql-client ant rpl --no-install-recommends && apt-get clean

COPY data /data
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]

