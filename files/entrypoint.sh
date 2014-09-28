#!/bin/bash
#
# Container entrypoint
#
# This file is executed when the container is run. It is responsible for
# setting up the environment before the requested command is executed.

MYSQL_LIB="/var/lib/mysql"
MYSQL_RUN="/var/run/mysqld"

# Create a directory owned by mysql
createDir() {
	DIR=$1
	mkdir -p "$DIR"
	chown mysql:mysql "$DIR"
	chmod 0755 "$DIR"
}

# Execute a mysql query
executeQuery() {
	QUERY=$1
	mysql --user="root" --password="$MYSQL_ROOT_PASSWORD" --execute="$QUERY"
	return $?
}

# Check for the mysql run directory
if [ ! -d "$MYSQL_RUN" -a ! -L "$MYSQL_RUN" ];
then
	createDir "$MYSQL_RUN"
fi

# Check for the mysql data directory
if [ ! -d "$MYSQL_LIB" -a ! -L "$MYSQL_LIB" ];
then
	createDir "$MYSQL_LIB"
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
	mysql_install_db --user="mysql" --datadir="$MYSQL_LIB" --basedir="/usr"
	mysqld --user="mysql" --disconnect_on_expired_password="OFF" > /dev/null &

	# Wait for the mysql daemon to start up and change the root password
	RET=1
	while [[ $RET -ne 0 ]];
	do
		sleep 3
		mysql --user="root" --password="$(tail -n1 /root/.mysql_secret)" --execute="SET PASSWORD = PASSWORD('$MYSQL_ROOT_PASSWORD')" > /dev/null
		RET=$?
	done

	# Remove anonymous user, create global root user, and drop test schema
	executeQuery "DELETE FROM mysql.user WHERE User='';"
	executeQuery "CREATE USER 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
	executeQuery "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;"
	executeQuery "DROP SCHEMA IF EXISTS \`test\`;"

	# Shutdown the mysql daemon
	mysqladmin --user="root" --password="$MYSQL_ROOT_PASSWORD" shutdown
fi

# Execute the command
exec "$@"
