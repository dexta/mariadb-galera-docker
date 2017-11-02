MariaDB Galera Docker
=====================
Automated deployment of the docker based MariaDB Galera cluster into Docker CE or EE.

## Requirements

The deployment assumes you have a cluster with remote API enabled, and that you have the certificates required to connect.  For example, a cluster built with [cluster-builder](https://github.com/ids/cluster-builder).

For __Docker CE__ built with cluster-builder, the certificates are stored in the deployment package folder (located in __clusters__), and the certificates are placed within the __api-certs__ folder.  The YAML configuration file discussed below would need a relative or absolute path to this folder.

For __Docker EE__ built with cluster-builder, the certificates must be downloaded through the UCP Web UI. The download package can be extracted, and within it will be the required certificates. The YAML configuration file discussed below would need a relative or absolute path to this folder.


## Notes

The service name for the galera-haproxy service is the entry point, so if the stack is named "tier1", then the address of the MariaDB cluster for mysql clients is: __tier1_galera-haproxy:3306__.  This is how other containers should connect to MariaDB.

> All custom YAML files should be stored in the __deploys__ folder.  These will be ignored by the source repo and should be managed by the user.

To test connection to the Swarm and validate the __api-certs__, load the configuration YAML file and run the docker-env wrapper script:

    source ./conf <galera configuration YAML>
    ./docker-env info

> The DOCKER_HOST and DOCKER_CERT_PATH values specified in the custom YAML configuration file are  used for deployment.  This is to ensure there is no accidental deployment to the wrong DOCKER environment.  To test using the __docker-env__ script the environment values must be manually loaded via the __conf__ script.

> The UCP bundle includes a file called __env.sh__, and encourages setting the docker context by evaluatiing this script (eg. __eval $(<env.sh)__).  But this feels too ambiguous an approach for production deployments.  It would be far too easy to forget to setup your environment and end up deploying to the wrong docker context - which could result in a very bad day.  For this reason, the certificates and environment are __explicitly__ specified in the deployment configurations.  It is recommended the naming convention of the YAML deployment configuration files also be explicit to the environment (eg. prod-web-main.yml).  This will hopefully mitigate the risk of accidently pushing a dev deployment into prod because an eval was missed.

The basic command to deploy is:

    bash deploy <galera configuration YAML>

Eg.

    bash deploy tier1_galera.yml

## YAML Configuration File Syntax
    
    docker-host: The manager node with remote api enabled
    docker-host-cert-path: The location of the docker remote api certificates

    stack-name: the name of the service stack deployment

    galera-node1: The dns name of the swarm node hosting node 1 of the galera cluster
    galera-node2: The dns name of the swarm node hosting node 2 of the galera cluster
    galera-node3: The dns name of the swarm node hosting node 3 of the galera cluster

    galera-network-name: The name of the overlay network for the cluster (default: galera_network)
    galera-network: The cluster network (default: 10.0.9.0/24)

    ssh-user: SSH user for creating initial data folders on the host nodes
    ssh-become: SSH become for non-root SSH accounts (default: sudo)

__Eg.__

    docker-host: demo-swarm-m1:2376
    docker-host-cert-path: "./api-certs/demo-swarm-m1"

    stack-name: tier1

    galera-node1: demo-swarm-w1
    galera-node2: demo-swarm-w2
    galera-node3: demo-swarm-w3

    galera-network-name: galera_network
    galera-network: 10.0.9.0/24

    ssh-user: admin
    ssh-become: sudo


## Data Loading

The default configuration closes all external access to MariaDB Cluster.  Only services running within the swarm can access the DB HAPROXY.  To enable easy data loading there are two scripts that toggle exposing the DB HAPROXY via port publishing 3306 externally.

To prepare the database for data loading / external access:

    bash db-open <galera configuration YAML>

This will enable external __mysql__ access.

When data loading is complete, external access can be closed again:

    bash db-close <galera configuration YAML>

