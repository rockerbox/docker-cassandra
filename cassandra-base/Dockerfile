# Spotify Cassandra 2.0 Base Image
#
# VERSION               0.1
#
# Installs Cassandra 2.0 package. Does only basic configuration.
# Tokens and seed nodes should be configured by child images.

FROM java:8

ENV DEBIAN_FRONTEND noninteractive

# Add DataStax sources
ADD datastax_key /tmp/datastax_key
RUN apt-key add /tmp/datastax_key
RUN echo "deb http://debian.datastax.com/community stable main" > /etc/apt/sources.list.d/datastax.list

# Workaround for https://github.com/docker/docker/issues/6345
RUN ln -s -f /bin/true /usr/bin/chfn

# Install Cassandra 2.2.0
RUN apt-get update && \
    apt-get install -y --force-yes cassandra=2.2.0 dsc22=2.2.0-1 && \
    rm -rf /var/lib/apt/lists/*

ENV CASSANDRA_CONFIG /etc/cassandra

# Necessary since cassandra is trying to override the system limitations
# See https://groups.google.com/forum/#!msg/docker-dev/8TM_jLGpRKU/dewIQhcs7oAJ
RUN rm -f /etc/security/limits.d/cassandra.conf

EXPOSE 7199 7000 7001 9160 9042 22 8012 61621

# For adding custom lucene index feature
# Note: this should be compiled on your machine and placed in this directory
COPY cassandra-lucene-index-plugin-2.1.8.0.jar /usr/share/cassandra/lib/
COPY rockerbox-analyzers.jar /usr/share/cassandra/lib/
#COPY metrics-graphite-2.2.0.jar /usr/share/cassandra/lib/
COPY TimeWindowCompactionStrategy-2.2.0.jar /usr/share/cassandra/lib/

COPY metrics-graphite-3.1.2.jar /usr/share/cassandra/lib/
COPY cassandra-metrics.yaml /etc/cassandra/
COPY cassandra.yaml /etc/cassandra/


CMD [""]
