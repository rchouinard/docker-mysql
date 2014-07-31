#!/bin/bash

MYSQL_LIB="/var/lib/mysql"
MYSQL_RUN="/var/run/mysqld"

createDir() {
	DIR=$1
	mkdir -p "$DIR"
	chown mysql:mysql "$DIR"
	chmod 0755 "$DIR"
}

if [ ! -d "$MYSQL_RUN" -a ! -L "$MYSQL_RUN" ];
then
	createDir "$MYSQL_RUN"
fi

if [ ! -d "$MYSQL_LIB" -a ! -L "$MYSQL_LIB" ];
then
	createDir "$MYSQL_LIB"
fi

if [ -z "$(ls -A $MYSQL_LIB)" -a "${1%_safe}" = "mysqld" ];
then
	if [ -z "$MYSQL_ROOT_PASSWORD" ];
	then
		echo >&2 "ERROR: Database is uninitialized and MYSQL_ROOT_PASSWORD not set"
		exit 1
	fi

	mysql_install_db --user=mysql --datadir="$MYSQL_LIB" --skip-random-passwords
	chown -R mysql:mysql "$MYSQL_LIB"

	mysqld --user=mysql > /dev/null &

	RET=1
	while [[ $RET -ne 0 ]];
	do
		sleep 3
		mysql --user=root --execute="STATUS" > /dev/null
		RET=$?
	done

	mysql --user=root --execute="DELETE FROM mysql.user WHERE User='';"
	mysql --user=root --execute="UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PASSWORD'), password_expired='N' WHERE User='root';"
	mysql --user=root --execute="CREATE USER 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
	mysql --user=root --execute="GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;"
	mysql --user=root --execute="DROP SCHEMA IF EXISTS \`test\`;"

	mysqladmin --user=root shutdown
fi

exec "$@"
