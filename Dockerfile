FROM ubuntu:trusty
MAINTAINER Ryan Chouinard <rchouinard@gmail.com>

#
# Add the official MySQL repository
#
# Since the GPG key isn't published anywhere, we have to ADD it to the
# container and import it from there. The key was extracted using
# `apt-key export 5072E1F5 > mysql-release-engineering.asc`. 
ADD files/mysql-release-engineering.asc /tmp/mysql-release-engineering.asc
RUN echo "deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-5.6" > /etc/apt/sources.list.d/mysql-community.list
RUN cat /tmp/mysql-release-engineering.asc | apt-key add -
RUN DEBIAN_FRONTEND=noninteractive apt-get update

#
# Install MySQL Community Server
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-community-server

#
# Add custom configuration
ADD files/00_charset.cnf /etc/mysql/conf.d/00_charset.cnf
ADD files/00_logging.cnf /etc/mysql/conf.d/00_logging.cnf
ADD files/00_network.cnf /etc/mysql/conf.d/00_network.cnf

#
# Remove default data
#
# The entrypoint will recreate as needed.
RUN rm -rf /var/lib/mysql/*

#
# Export data directory
VOLUME /var/lib/mysql

#
# Set custom entrypoint
ADD files/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#
# Export port 3306
EXPOSE 3306

#
# Execute the default command
#
# This is passed through to the entrypoint for execution
CMD ["mysqld", "--user=mysql"]
