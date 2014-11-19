#!/bin/bash
#
# Container entrypoint
#
# This file is executed when the container is run. It is responsible for
# setting up the environment before the requested command is executed.

MYSQL_LIB="/var/lib/mysql"
MYSQL_RUN="/var/run/mysqld"
MYSQL_BASEDIR="/usr"

# Create a directory owned by mysql
createDir() {
	mkdir --parents "$1"
	chown mysql:mysql "$1"
	chmod $2 "$1"
}

# Execute a mysql query
executeQuery() {
	mysql --user="root" --password="$MYSQL_ROOT_PASSWORD" --execute="$1" > /dev/null 2>&1
	return $?
}

# Check for the mysql run directory
if [ ! -d "$MYSQL_RUN" -a ! -L "$MYSQL_RUN" ];
then
	createDir "$MYSQL_RUN" 0755
fi

# Check for the mysql data directory
if [ ! -d "$MYSQL_LIB" -a ! -L "$MYSQL_LIB" ];
then
	createDir "$MYSQL_LIB" 0700
fi

# If the data directory is empty and the command is mysqld or mysqld_safe...
if [ -z "$(ls -A $MYSQL_LIB)" -a "${1%_safe}" = "mysqld" ];
then

	# Check if we have a password
	if [ -z "$MYSQL_ROOT_PASSWORD" ];
	then
		echo >&2 "ERROR: Database is uninitialized and MYSQL_ROOT_PASSWORD not set"
		exit 1
	fi

	# Initialize the data directory and start the mysql daemon
	mysql_install_db --user="mysql" --datadir="$MYSQL_LIB" --basedir="$MYSQL_BASEDIR" --random-passwords
	mysqld --user="mysql" --disconnect_on_expired_password="OFF" > /dev/null &

	# Wait for the mysql daemon to start up and change the root password
	started=false
	for i in {1..10}; do
		mysqladmin ping > /dev/null 2>&1
		if [[ $? -eq 0 ]]; then
			started=true
			break
		fi
		sleep 1
	done
	if [ "$started" != true ]; then
		echo >&2 "ERROR: MySQL failed to start"
		exit 1
	fi

	# Reset root password
	mysqladmin --user="root" --password="$(cat /root/.mysql_secret | rev | cut -d' ' -f1 | rev)" password "$MYSQL_ROOT_PASSWORD" > /dev/null 2>&1

	# Create host-less root user
	executeQuery "CREATE USER 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
	executeQuery "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;"

	# Shutdown the mysql daemon
	mysqladmin --user="root" --password="$MYSQL_ROOT_PASSWORD" shutdown > /dev/null 2>&1
fi

# Execute the command
exec "$@"
