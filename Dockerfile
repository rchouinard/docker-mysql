FROM ubuntu:trusty
MAINTAINER Ryan Chouinard <rchouinard@gmail.com>

#
# Add the official MySQL repository
RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 8C718D3B5072E1F5
RUN echo "deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-5.7-dmr" > /etc/apt/sources.list.d/mysql-community.list
RUN DEBIAN_FRONTEND=noninteractive apt-get update

#
# Install MySQL Community Server
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-community-server

#
# Add custom configuration
ADD files/conf.d/ /etc/mysql/conf.d/

#
# Remove default data
#
# The entrypoint will recreate as needed.
RUN rm -rf /var/lib/mysql/*

#
# Export data directory
VOLUME /var/lib/mysql

#
# Export port 3306
EXPOSE 3306

#
# Set custom entrypoint
ADD files/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#
# Set the default command
#
# This is passed through to the entrypoint for execution
CMD ["mysqld", "--user=mysql"]
