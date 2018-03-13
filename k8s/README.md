MariaDB Galera Docker on Kubernetes
===================================

Still early in the development of the k8s version.

> Make sure to clear out the iSCSI volumes between cluster creations.  If there is existing galera data on the volumes the clusters will try to recover instead of forming new nodes.

> This has been tested and developed on the __Tectonic CoreOS__ cluster from [cluster-builder](https://github.com/ids/cluster-builder).

This configuration uses iSCSI direct access for the persistent data volumes.  It requires access to an iSCSI target that contains at least 4 luns: 1 for the initial seed volume which will be discarded, and 3 or 5 nodes for the permanent node volumes.

## Temporary Ansible Approach

It uses ansible templates to generate a __MariaDB Galera__ yaml manifests based on configuration information supplied via an ansible inventory file.

The templates generate two sets of configuration files:

* 3-node
* 5-node

In the __clusters__ folder create a sub-folder that matches the name of the prefix for the galera cluster name (see the example in the __tier1-example__ folder), or copy the __tier1-example__ folder and rename it.

Add or adjust the ansible configuration file with the specifics to your environment, see the __galera.conf__ file in the __tier1-example__ example.

Run the ansible playbook to generate the Kubernetes YAML deployment manifests:

    $ ansible-playbook -i clusters/tier1-example/galera.conf mariadb-galera-template.yml

This will create a set of output manifest files that can then be deployed to Kubernetes.  Select either the 3 or 5 node deployment scripts depending on the size of the cluster to deploy:

There is also two variants of deployment:

* Without Backup Agent
* With Integrated NFS Backup Agent


### 3 or 5 Node Galera

> In the examples below simply replace 3 with 5 in the manifest names if you wish to deploy a 5 node cluster.

#### Step 1 - Setup Persistent Volumes

From within the 3-node galera cluster folder, apply the configurations in order:

    kubectl apply -f galera-3-volumes.yml

This will setup the persistent volumes to the iSCSI LUNs.

#### Step 2 - Launch the Seed Instance

    kubectl apply -f galera-3-seed.yml

This will bring up the seed instance of mysql... wait until it starts and is ready with mysql accepting connections before moving on to the nodes.

#### Step 3 - Launch the Permanent Galera Nodes

If you wish to deploy without a backup agent, use:

    kubectl apply -f galera-3-nodes.yml

Or, with a backup agent:

    kubectl apply -f galera-3-nodes-backup.yml

The nodes should come up fairly quickly.  Once they are all up and ready, start the HAProxy:

#### Step 4 - Start the DB HAProxy

    kubectl apply -f galera-3-haproxy.yml

#### Step 5 - Decomission the Seed Node

Delete the seed node:

    kubectl delete -f galera-3-seed.yml

Which should leave a 3 or 5 node cluster fronted by the HAProxy.

`kubectl exec` into any of the nodes and verify the cluster:

    mysql -u mariadb-galera-haproxy -u root -p
    > show status like '%wsrep%';

It should show the 3 or 5 node cluster configuration information.

You can then enable and disable external access to the cluster (for data loading):

#### Enable/Disable External Access

    kubectl apply -f galera-external-access.yml

This will open up the specified __NodePort__ on all of the worker nodes.

    mysql -h <address of worker node> --port <node port specified> -u root -p

Will give you access to the running galera cluster through the HAProxy.

    kubectl delete -f galera-external-access.yml

Will close off external access.

## MariaDB Helm Chart

This is the correct way to deal with the sort of configuration requirements of a stack deployment:

https://docs.helm.sh/

Coming Soon.
