FROM debian:stretch as builder

# Install ant, unzip, java, rpl, and a mysql client
RUN apt-get update && apt-get dist-upgrade -y && \
    apt-get install -y mysql-client unzip default-jdk ant rpl --no-install-recommends

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["sh", "/entrypoint.sh"]
