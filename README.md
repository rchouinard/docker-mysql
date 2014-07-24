MySQL in a Container
====================

This is a Docker project to run MySQL using the official repositories.
Why? So I can have the latest MySQL release available, and learn more about
Docker in the process.

Building
--------

Building is straight forward:

    git clone git@github.com:rchouinard/docker-mysql.git
    cd docker-mysql
    docker build -t rchouinard/mysql .

Running
-------

Also fairly straight forward, but there are a few caveats:

    docker run \
        -d \
        -v $HOME/mysql56:/var/lib/mysql \
        -p 13306:3306 \
        -e "MYSQL_ROOT_PASSWORD=mysecretpassword" \
        rchouinard/mysql:latest

This command will create a new container based on the new MySQL image built
previously.

 - `-d` tells Docker to run the container as a daemon
 - `-v $HOME/mysql56:/var/lib/mysql` maps the local path `~/mysql56` to
`/var/lib/mysql` inside the container. This allows the MySQL data to persist
across runs.
 - `-p 13306:3306` maps the local port `13306` to the container's port `3306`.
This lets us connect to the instance as shown below.
 - `-e "MYSQL_ROOT_PASSWORD=mysecretpassword"` sets the root password for the
instance. This really only needs to be specified on the first run.
 - `rchouinard/mysql:latest` uses the latest rchouinard/mysql image for the container.

Be sure to adjust any of the parameters to meet your requirements.

Connecting
----------

If you used the run command above, you can now connect to the instance using
your client of choice.

    mysql -uroot -p -h127.0.0.1 -P13306

Use the password you selected above (`mysecretpassword` in the example) and you
should be greeted with the server banner. Yay!

Doing More
----------

Of course there's more. You can link this container to other containers to
create an application using your new MySQL instance. Consult the
[Docker documentation](https://docs.docker.com/) for more information.
