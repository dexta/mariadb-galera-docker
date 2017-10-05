MariaDB Galera Docker
=====================

This is a containerized version of a MariaDB Galera cluster.  It makes use of shim scripts to manage and control the cluster startup and syncronization through declarative container infrastructure and orchestration.

> The underlying mariadb-galera-docker container is based on [mariadb-galera-swarm](https://github.com/colinmollenhour/mariadb-galera-swarm)

It currently works in both Docker Swarm and DC/OS using the same Docker images.

See the [dcos](./dcos) README for instructions on deploying to DC/OS.

See the [swarm](./swarm) README for instructions on deploying to Docker Swarm.
