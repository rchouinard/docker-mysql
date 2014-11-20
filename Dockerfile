FROM debian:wheezy
MAINTAINER Ryan Chouinard <rchouinard@gmail.com>

#
# Install MySQL Community Server from the official APT repo
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8C718D3B5072E1F5 \
    && echo "deb http://repo.mysql.com/apt/debian/ wheezy mysql-5.7-dmr" > /etc/apt/sources.list.d/mysql-community.list \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get --yes install \
        mysql-community-server=5.7.5-m15-1debian7 \
    && DEBIAN_FRONTEND=noninteractive apt-get clean \
    && rm --recursive --force /var/lib/mysql/*

#
# Add custom files
ADD files/conf.d/ /etc/mysql/conf.d/
ADD files/entrypoint.sh /entrypoint.sh

#
# Export container resources
VOLUME /var/lib/mysql
EXPOSE 3306

#
# Set custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]

#
# Set the default command
#
# This is passed through to the entrypoint for execution
CMD ["mysqld", "--user=mysql"]
