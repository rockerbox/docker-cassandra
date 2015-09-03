#!/usr/bin/env bash

# Get running container's IP
IP=`hostname --ip-address | cut -f 1 -d ' '`
if [ $# == 1 ]; then SEEDS="$1,$IP"; 
else SEEDS="$IP"; fi

# Setup cluster name
if [ -z "$CASSANDRA_CLUSTERNAME" ]; then
        echo "No cluster name specified, preserving default one"
else
        sed -i -e "s/^cluster_name:.*/cluster_name: $CASSANDRA_CLUSTERNAME/" $CASSANDRA_CONFIG/cassandra.yaml
fi

# Dunno why zeroes here
sed -i -e "s/^rpc_address.*/rpc_address: $IP/" $CASSANDRA_CONFIG/cassandra.yaml

# Listen on IP:port of the container
sed -i -e "s/^listen_address.*/listen_address: $IP/" $CASSANDRA_CONFIG/cassandra.yaml

#sed -i -e "s/^#MAX_HEAP_SIZE=\"4G\"/MAX_HEAP_SIZE=\"6G\"/" $CASSANDRA_CONFIG/cassandra-env.sh

#sed -i -e "s/^#HEAP_NEWSIZE=\"800M\"/HEAP_NEWSIZE=\"1200M\"/" $CASSANDRA_CONFIG/cassandra-env.sh

# Enable remote JMX connections
sed -i -e "s/^LOCAL_JMX=yes/LOCAL_JMX=no/" $CASSANDRA_CONFIG/cassandra-env.sh
sed -i -e "s/JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote.authenticate=true\"/JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote.authenticate=false\"/" $CASSANDRA_CONFIG/cassandra-env.sh
sed -i -e "s/JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote.password.file=\/etc\/cassandra\/jmxremote.password\"/#JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote.password.file=\/etc\/cassandra\/jmxremote.password\"/" $CASSANDRA_CONFIG/cassandra-env.sh

# Configure Cassandra seeds
if [ -z "$CASSANDRA_SEEDS" ]; then
	echo "No seeds specified, being my own seed..."
	CASSANDRA_SEEDS=$SEEDS
fi
sed -i -e "s/- seeds: \"127.0.0.1\"/- seeds: \"$CASSANDRA_SEEDS\"/" $CASSANDRA_CONFIG/cassandra.yaml

# Most likely not needed
echo "JVM_OPTS=\"\$JVM_OPTS -Djava.rmi.server.hostname=$IP\"" >> $CASSANDRA_CONFIG/cassandra-env.sh
echo "JVM_OPTS=\"\$JVM_OPTS -Dcassandra.metricsReporterConfigFile=/etc/cassandra/cassandra-metrics.yaml\"" >> $CASSANDRA_CONFIG/cassandra-env.sh

echo "Starting Cassandra on $IP..."

cassandra -f
