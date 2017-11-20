#!/bin/bash

sleep 5
echo "Setting up HA PROXY..."

printf "HAPROXY_GALERA_NODE_1=${HAPROXY_GALERA_NODE_1}\n" >> /etc/default/haproxy
printf "HAPROXY_GALERA_NODE_2=${HAPROXY_GALERA_NODE_2}\n" >> /etc/default/haproxy
printf "HAPROXY_GALERA_NODE_3=${HAPROXY_GALERA_NODE_3}\n" >> /etc/default/haproxy
printf "HAPROXY_GALERA_TIMEOUT=${HAPROXY_GALERA_TIMEOUT}\n" >> /etc/default/haproxy

echo "NODE_1: ${HAPROXY_GALERA_NODE_1}"
echo "NODE_2: ${HAPROXY_GALERA_NODE_2}"
echo "NODE_3: ${HAPROXY_GALERA_NODE_3}"
echo "TIMEOUT: ${HAPROXY_GALERA_TIMEOUT}"

echo "Starting HA PROXY..."
haproxy -f /usr/local/etc/haproxy/haproxy.cfg -V