MariaDB Galera Docker on Kubernetes
===================================

Still early in the development of the k8s version.

> Make sure to clear out the iSCSI volumes between cluster creations.  If there is existing galera data on the volumes the clusters will try to recover instead of forming new nodes.

> This has been tested and developed on the Tectonic CoreOS cluster from [cluster-builder](https://github.com/ids/cluster-builder).

This configuration uses iSCSI direct access for the persistent data volumes.  It requires access to an iSCSI target that contains at least 4 luns: 1 for the initial seed volume which will be discarded, and 3 for the permanent node volumes.

## Temporary Ansible Approach

It uses ansible templates to generate a __MariaDB Galera__ yaml manifests based on configuration information supplied via an ansible inventory file.

In the __clusters__ folder create a sub-folder that matches the name of the prefix for the galera cluster name (see the example in the __tier1-example__ folder).

Add an ansible configuration file with the specifics to your environment, see the __galera.conf__ file in the __tier1-example__ example.

Run the ansible playbook to generate the Kubernetes YAML deployment manifests:

    $ ansible-playbook -i clusters/tier1-example/galera.conf mariadb-galera-template.yml

This will create a set of output manifest files that can then be deployed to Kubernetes:

From within the galera cluster folder, apply the configurations in order:

    kubectl apply -f galera-volumes.yml

This will setup the persistent volumes to the iSCSI LUNs.

    kubectl apply -f galera-seed.yml

This will bring up the seed volume... wait until it starts and is ready with mysql accepting connections before moving on to the nodes.

    kubectl apply -f galera-nodes.yml

The nodes should come up fairly quickly.  Once they are all up and ready, start the HAProxy:

    kubectl apply -f galera-haproxy.yml

And then delete the seed node:

    kubectl delete -f galera-seed.yml

Which should leave a 3 node cluster fronted by the HAProxy.

`kubectl exec` into any of the nodes and verify the cluster:

    mysql -u mariadb-galera-haproxy -u root -p
    > show status like '%wsrep%';

It should show the 3 node cluster configuration information.

You can then enable and disable external access to the cluster (for data loading):

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