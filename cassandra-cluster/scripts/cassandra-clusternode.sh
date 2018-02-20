#!/usr/bin/env bash
set -e


sed -i -e 's/&& \[ "$JVM_PATCH_VERSION" -ge "60" \]//' $CASSANDRA_CONFIG/cassandra-env.sh
sed -i -e 's/&& \[ "$JVM_PATCH_VERSION" \\< "25" \]/&& \[ "$JVM_PATCH_VERSION" \\< "1.7" \]/' $CASSANDRA_CONFIG/cassandra-env.sh

sed -i -e "s/^LOCAL_JMX=yes/LOCAL_JMX=no/" $CASSANDRA_CONFIG/cassandra-env.sh
sed -i -e "s/JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote.authenticate=true\"/JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote.authenticate=false\"/" $CASSANDRA_CONFIG/cassandra-env.sh
sed -i -e "s/JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote.password.file=\/etc\/cassandra\/jmxremote.password\"/#JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote.password.file=\/etc\/cassandra\/jmxremote.password\"/" $CASSANDRA_CONFIG/cassandra-env.sh

echo "JVM_OPTS=\"\$JVM_OPTS -Dcassandra.metricsReporterConfigFile=/etc/cassandra/cassandra-metrics.yaml\"" >> $CASSANDRA_CONFIG/cassandra-env.sh

HOSTNAME=$(hostname)
if [ -z "$CASSANDRA_SEEDS" ]; then
  CASSANDRA_SEEDS=$(hostname)
fi

POD_IP="${POD_IP:-$HOSTNAME}"

CASSANDRA_CLUSTER_NAME="${CASSANDRA_CLUSTER_NAME:-Test Cluster}"
CASSANDRA_CONCURRENT_READS="${CASSANDRA_CONCURRENT_READS:-32}"
CASSANDRA_CONCURRENT_WRITES="${CASSANDRA_CONCURRENT_WRITES:-32}"
CASSANDRA_DC="${CASSANDRA_DC}"
CASSANDRA_ENDPOINT_SNITCH="${CASSANDRA_ENDPOINT_SNITCH:-SimpleSnitch}"
CASSANDRA_GC_STDOUT="${CASSANDRA_GC_STDOUT:-false}"
CASSANDRA_INTERNODE_COMPRESSION="${CASSANDRA_INTERNODE_COMPRESSION:-all}"
CASSANDRA_LISTEN_ADDRESS="${CASSANDRA_LISTEN_ADDRESS:-$POD_IP}"

CASSANDRA_MEMTABLE_ALLOCATION_TYPE="${CASSANDRA_MEMTABLE_ALLOCATION_TYPE:-heap_buffers}"
CASSANDRA_NUM_TOKENS="${CASSANDRA_NUM_TOKENS:-256}"
CASSANDRA_RACK="${CASSANDRA_RACK}"
CASSANDRA_RPC_ADDRESS="${CASSANDRA_RPC_ADDRESS:-$HOSTNAME}"
CASSANDRA_SEED_PROVIDER="${CASSANDRA_SEED_PROVIDER:-org.apache.cassandra.locator.SimpleSeedProvider}"
CASSANDRA_SEEDS="${CASSANDRA_SEEDS:false}"

echo Starting Cassandra on ${CASSANDRA_LISTEN_ADDRESS}
echo CASSANDRA_CONFIG ${CASSANDRA_CONFIG}
echo CASSANDRA_CLUSTER_NAME ${CASSANDRA_CLUSTER_NAME}
echo CASSANDRA_COMPACTION_THROUGHPUT_MB_PER_SEC ${CASSANDRA_COMPACTION_THROUGHPUT_MB_PER_SEC}
echo CASSANDRA_CONCURRENT_COMPACTORS ${CASSANDRA_CONCURRENT_COMPACTORS}
echo CASSANDRA_CONCURRENT_READS ${CASSANDRA_CONCURRENT_READS}
echo CASSANDRA_CONCURRENT_WRITES ${CASSANDRA_CONCURRENT_WRITES}
echo CASSANDRA_DC ${CASSANDRA_DC}
echo CASSANDRA_ENDPOINT_SNITCH ${CASSANDRA_ENDPOINT_SNITCH}
echo CASSANDRA_INTERNODE_COMPRESSION ${CASSANDRA_INTERNODE_COMPRESSION}
echo CASSANDRA_LISTEN_ADDRESS ${CASSANDRA_LISTEN_ADDRESS}
echo CASSANDRA_MEMTABLE_ALLOCATION_TYPE ${CASSANDRA_MEMTABLE_ALLOCATION_TYPE}
echo CASSANDRA_NUM_TOKENS ${CASSANDRA_NUM_TOKENS}
echo CASSANDRA_RACK ${CASSANDRA_RACK}
echo CASSANDRA_RPC_ADDRESS ${CASSANDRA_RPC_ADDRESS}
echo CASSANDRA_SEEDS ${CASSANDRA_SEEDS}
echo CASSANDRA_SEED_PROVIDER ${CASSANDRA_SEED_PROVIDER}

if [[ $CASSANDRA_DC && $CASSANDRA_RACK ]]; then
  echo "dc=$CASSANDRA_DC" > $CASSANDRA_CONFIG/cassandra-rackdc.properties
  echo "rack=$CASSANDRA_RACK" >> $CASSANDRA_CONFIG/cassandra-rackdc.properties
  CASSANDRA_ENDPOINT_SNITCH="GossipingPropertyFileSnitch"
fi

for rackdc in dc rack; do
  var="CASSANDRA_${rackdc^^}"
  val="${!var}"
  if [ "$val" ]; then
	sed -ri 's/^('"$rackdc"'=).*/\1 '"$val"'/' "$CASSANDRA_CONFIG/cassandra-rackdc.properties"
  fi
done

for yaml in \
  cluster_name \
  endpoint_snitch \
  listen_address \
  num_tokens \
  rpc_address \
  start_rpc \
  concurrent_reads \
  concurrent_writes \
  memtable_allocation_type \
  concurrent_compactors \
  compaction_throughput_mb_per_sec \
  internode_compression \
  ; do
  var="CASSANDRA_${yaml^^}"
  val="${!var}"
  if [ "$val" ]; then
    sed -ri 's/^(# )?('"$yaml"':).*/\2 '"$val"'/' "$CASSANDRA_CONFIG/cassandra.yaml"
  fi
done

if [[ $CASSANDRA_SEEDS == 'false' ]]; then
  sed -ri 's/- seeds:.*/- seeds: "'"$POD_IP"'"/' $CASSANDRA_CONFIG/cassandra.yaml
else
  sed -ri 's/- seeds:.*/- seeds: "'"$CASSANDRA_SEEDS"'"/' $CASSANDRA_CONFIG/cassandra.yaml
fi

sed -ri 's/- class_name: SEED_PROVIDER/- class_name: '"$CASSANDRA_SEED_PROVIDER"'/' $CASSANDRA_CONFIG/cassandra.yaml

if [[ $CASSANDRA_GC_STDOUT == 'true' ]]; then
  sed -ri 's/ -Xloggc:\/var\/log\/cassandra\/gc\.log//' $CASSANDRA_CONFIG/cassandra-env.sh
fi

sed -i -e "s/^enable_user_defined_functions: false/enable_user_defined_functions: true/" $CASSANDRA_CONFIG/cassandra.yaml

echo "JVM_OPTS=\"\$JVM_OPTS -Djava.rmi.server.hostname=$POD_IP\"" >> $CASSANDRA_CONFIG/cassandra-env.sh

echo "Starting Cassandra on $CASSANDRA_LISTEN_ADDRESS..."

cassandra -f
