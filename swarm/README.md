MariaDB Galera Swarm
====================
Automated deployment of the docker based MariaDB Galera cluster into Docker Swarm.

## Notes

- The service name for the galera-haproxy service is the entry point, so if the stack is named "tier1", then the address of the MariaDB cluster for mysql clients is: __tier1_galera-haproxy:3306__.  This is how other containers should connect to MariaDB.

## Setup

Configuration details have been distilled into a simple YAML configuration file that is read by the BASH script that co-ordinates the stages of deploying a 3 node cluster.

- Copy the __galera-example.yml__ configuration script to __galera.yml__ for the default configuration that works with [cluster-builder](https://github.com/ids/cluster-builder) demo swarms.
- Copy the __sample-secrets__ folder to __.secrets__ and adjust the values as required
- Copy the __api-certs__ for the target cluster into the __api-certs__ folder and validate you can connect.

To test connection to the Swarm and validate the __api-certs__:

    bash ./docker-env info

The basic command to deploy is:

    bash deploy <stack name> [galera configuration yml file name]

When no configuration file is supplied, it looks in the current path for a __galera.yml__ file.

Eg.

    bash deploy tier1 tier1_galera.yml

## YAML Configuration File Syntax
    
    docker-host: The manager node with remote api enabled
    docker-port: The manager port (default: 2376)

    galera-node1: The dns name of the swarm node hosting node 1 of the galera cluster
    galera-node2: The dns name of the swarm node hosting node 2 of the galera cluster
    galera-node3: The dns name of the swarm node hosting node 3 of the galera cluster

    galera-network-name: The name of the overlay network for the cluster (default: galera_network)
    galera-network: The cluster network (default: 10.0.9.0/24)

    ssh-user: SSH user for creating initial data folders on the host nodes
    ssh-become: SSH become for non-root SSH accounts (default: sudo)

__Eg.__

    docker-host: demo-swarm-m1
    docker-port: 2376

    galera-node1: demo-swarm-w1
    galera-node2: demo-swarm-w2
    galera-node3: demo-swarm-w3

    galera-network-name: galera_network
    galera-network: 10.0.9.0/24

    ssh-user: admin
    ssh-become: sudo

