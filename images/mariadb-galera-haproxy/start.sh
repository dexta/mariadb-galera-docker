#!/bin/bash

sleep 5
echo "Setting up HA PROXY..."

[ -z $HAPROXY_GALERA_TIMEOUT ] && HAPROXY_GALERA_TIMEOUT=10800

printf "HAPROXY_GALERA_NODE_1=${HAPROXY_GALERA_NODE_1}\n" >> /etc/default/haproxy
printf "HAPROXY_GALERA_NODE_2=${HAPROXY_GALERA_NODE_2}\n" >> /etc/default/haproxy
printf "HAPROXY_GALERA_NODE_3=${HAPROXY_GALERA_NODE_3}\n" >> /etc/default/haproxy
printf "HAPROXY_GALERA_TIMEOUT=${HAPROXY_GALERA_TIMEOUT}\n" >> /etc/default/haproxy

[ -z $NODE_COUNT ] && NODE_COUNT=3

echo "NODE_COUNT: ${HAPROXY_GALERA_NODE_COUNT}"
echo "TIMEOUT: ${HAPROXY_GALERA_TIMEOUT}"

if [ "$NODE_COUNT" == "3" ]; then
  echo "NODE_1: ${HAPROXY_GALERA_NODE_1}"
  echo "NODE_2: ${HAPROXY_GALERA_NODE_2}"
  echo "NODE_3: ${HAPROXY_GALERA_NODE_3}"

  echo "Starting 3-Node HA PROXY..."
  haproxy -f /usr/local/etc/haproxy/haproxy3.cfg -V
else
  echo "NODE_1: ${HAPROXY_GALERA_NODE_1}"
  echo "NODE_2: ${HAPROXY_GALERA_NODE_2}"
  echo "NODE_3: ${HAPROXY_GALERA_NODE_3}"
  echo "NODE_4: ${HAPROXY_GALERA_NODE_4}"
  echo "NODE_5: ${HAPROXY_GALERA_NODE_5}"

  echo "Starting 5-Node HA PROXY..."
  haproxy -f /usr/local/etc/haproxy/haproxy5.cfg -V
fi


