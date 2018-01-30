MariaDB Galera Docker
=====================
Automated deployment of the docker based MariaDB Galera cluster into Docker CE or EE.

## Requirements

The deployment assumes you have a cluster with remote API enabled, and that you have the certificates required to connect.  For example, a cluster built with [cluster-builder](https://github.com/ids/cluster-builder).

For __Docker CE__ built with cluster-builder, the certificates are stored in the deployment package folder (located in __clusters__), and the certificates are placed within the __api-certs__ folder.  The YAML configuration file discussed below would need a relative or absolute path to this folder.

For __Docker EE__ built with cluster-builder, the certificates must be downloaded through the UCP Web UI. The download package can be extracted, and within it will be the required certificates. The YAML configuration file discussed below would need a relative or absolute path to this folder.

## Notes

The service name for the galera-haproxy service is the entry point, so if the stack is named "tier1", then the address of the MariaDB cluster for mysql clients is: __tier1_galera-haproxy:3306__.  This is how other containers should connect to MariaDB.

If you are using __cluster-builder__ it is easiest to do a symbolic link to the path where you store your cluster definition files.  For example, from the root project directory: 

    ln -s <path to cluster-builder clusters folder> clusters

This project will ignore the clusters folder, and automatically look in that folder as a base path for deployment configurations.

To configure a deployment see the example configuration files in the __examples__ folder.  The stack files use environment variables for configuration.

To test connection to the Docker Swarm and validate that your configuration points to the correct __api-certs__ folder, load the configuration file and run the docker-env wrapper script:

    source ./conf <path to galera configuration file>
    ./docker-env info

> The DOCKER_HOST and DOCKER_CERT_PATH values specified in the configuration file are used for deployment.  This is to ensure there is no accidental deployment to the wrong DOCKER environment.  To test using the __docker-env__ script the environment values must be manually loaded via the __conf__ script.

> The UCP bundle includes a file called __env.sh__, and encourages setting the docker context by evaluating this script (eg. __eval $(<env.sh)__).  But this feels too ambiguous an approach for production deployments.  It would be far too easy to forget to setup your environment and end up deploying to the wrong docker context - which could result in a very bad day.  For this reason, the certificates and environment are __explicitly__ specified in the deployment configurations.  It is recommended the naming convention of the YAML deployment configuration files also be explicit to the environment (eg. prod-web-main.conf).  This will hopefully mitigate the risk of accidently pushing a dev deployment into prod because an eval was missed.

__VMware Volume Driver Service__ only works for **Docker 17.09** or greater, which at present is only **Docker CE**... the next release of EE should support it and is coming soon.

## Deployment

The basic command to deploy is:

    bash deploy <galera configuration file>

Eg.

    bash deploy tier1_galera.conf

## Private Registry Authentication via the API
If your images are stored in a private registry that requires authentication, such as gitlab, you have to configure your local docker authorization credentials to pass the HTTP HEADER to the remote API:

1. In the __credentials__ folder, run the __gen-token__ script.
2. Take the output and add it to your ~/.docker/config.json file on the machine from which you are deploying.

Eg.

    "HttpHeaders": {
        "X-Registry-Auth": "<HEADER string from above>"
    }

See https://github.com/docker/docker.github.io/blob/master/swarm/swarm-api.md for details.

> You should then be able to deploy images from the private registry.  The authentication information will be passed via the HTTP HEADER, and then passed on to the worker nodes.

## Configuration File Example
    
    DOCKER_HOST=The manager node with remote api enabled
    DOCKER_CERT_PATH=The location of the docker remote api certificates

    STACK_NAME=the name of the service stack deployment

    GALERA_NODE1=The dns name of the swarm node hosting node 1 of the galera cluster
    GALERA_NODE2=... node 2 ...
    GALERA_NODE3=... node 3 ...

    GALERA_IMAGE=The name of the galera image to use (before the :)
    GALERA_TAG=The tag/version of the galera image to use (after the :)

    HAPROXY_IMAGE=The name of the galera haproxy image to use (before the :)
    HAPROXY_TAG=The tag/version of the galera haproxy image to use (after the :)
    
    GALERA_NETWORK_NAME=The name of the overlay network for the cluster (default: galera_network)
    GALERA_NETWORK=The cluster network (default: 10.0.9.0/24)

    APP_NETWORK=The app network (default: 10.0.9.0/24)
    APP_NETWORK_NAME=The name of the overlay network in which the HAProxy listens for requests (default: web_network)

    SSH_USER=SSH user for creating initial data folders on the host nodes
    SSH_BECOME=SSH become for non-root SSH accounts (default: sudo) 

__Eg.__

    DOCKER_HOST=demo-swarm-m1:2376
    DOCKER_CERT_PATH="./api-certs/demo-swarm-m1"

    STACK_NAME=tier1

    GALERA_NODE1=demo-swarm-w1
    GALERA_NODE2=demo-swarm-w2
    GALERA_NODE3=demo-swarm-w3

    GALERA_IMAGE=idstudios/mariadb-galera-docker
    GALERA_TAG=10.1

    HAPROXY_TAG=latest
    HAPROXY_IMAGE=idstudios/mariadb-galera-haproxy

    GALERA_NETWORK_NAME=data_network
    GALERA_NETWORK=10.0.9.0/24

    APP_NETWORK=192.168.42.0/24
    APP_NETWORK_NAME=web_network

    SSH_USER=admin
    SSH_BECOME=sudo 

Or to use the __VMware Docker Volume Service__ version:

    DOCKER_HOST=swarm-api.idstudios.local:2376
    DOCKER_CERT_PATH="./api-certs/ids/swarm-c1/api-certs"

    STACK_NAME=tier1

    USE_VDVS=true
    HOST_NODE_VOLUME_SIZE=5gb
    HOST_NODE_DATASTORE=san

    GALERA_IMAGE=idstudios/mariadb-galera-docker
    GALERA_TAG=10.1

    HAPROXY_TAG=latest
    HAPROXY_IMAGE=idstudios/mariadb-galera-haproxy

    GALERA_NETWORK_NAME=data_network
    GALERA_NETWORK=10.0.9.0/24

    APP_NETWORK=192.168.42.0/24
    APP_NETWORK_NAME=web_network


> Example configuration files can be found in the __examples__ folder.

## Data Loading

The default configuration closes all external access to MariaDB Cluster.  Only services running within the swarm can access the DB HAPROXY.  To enable easy data loading there are two scripts that toggle exposing the DB HAPROXY via port publishing 3306 externally.

To prepare the database for data loading / external access:

    bash db-open <galera configuration file>

This will enable external __mysql__ access.

When data loading is complete, external access can be closed again:

    bash db-close <galera configuration file>


## Simulate Hard Crash Recovery

To immediately scale all nodes to zero, killing the server processes, and then restart them.  Metaphorically pulling the plug on the servers.

> Demonstrates the socat based node information exchange mechanism for auto-assessing the node state and determining the most recent GTID.  Implemented as part of the mysqld.sh custom shim script in the container for galera node coordination.

    bash db-restart <galera configuration file>


## Rolling Upgrade from MariaDB 10.1 to 10.2

The default deployment is based on MariaDB 10.1.  The upgrade script will migrate the cluster to a newer container version, one node at a time, without taking the cluster offline:

    bash upgrade <galera configuration file> <version tag>

Eg.

    bash upgrade galera-demo-swarm.conf 10.2

This demonstration is even more impressive if you use it with the [drupal7-docker](https://github.com/ids/drupal7-docker) project, as you can validate the site loads before, during and after the upgrade.

> At the present time only versions 10.1 and 10.2 are implemented.