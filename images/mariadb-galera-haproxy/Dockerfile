FROM haproxy:1.7
COPY haproxy3.cfg /usr/local/etc/haproxy/haproxy3.cfg
COPY haproxy5.cfg /usr/local/etc/haproxy/haproxy5.cfg
COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh
ENTRYPOINT ["/usr/local/bin/start.sh"]
