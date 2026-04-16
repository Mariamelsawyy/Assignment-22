#!/bin/bash

# Clean up stale PID files from previous runs
rm -f /tmp/*.pid
rm -f $HADOOP_HOME/logs/*.pid

echo "Starting services on $(hostname)..."

# ---------------- ZOOKEEPER ----------------

if [[ "$(hostname)" == "node01" ]]; then
    echo "1" > /opt/data/zookeeper/myid
elif [[ "$(hostname)" == "node02" ]]; then
    echo "2" > /opt/data/zookeeper/myid
elif [[ "$(hostname)" == "node03" ]]; then
    echo "3" > /opt/data/zookeeper/myid
fi

if [[ "$(hostname)" == "node01" || "$(hostname)" == "node02" || "$(hostname)" == "node03" ]]; then
    /opt/zookeeper/bin/zkServer.sh start
fi

sleep 5

# ---------------- JOURNALNODE ----------------

if [[ "$(hostname)" == "node01" || "$(hostname)" == "node02" || "$(hostname)" == "node03" ]]; then
    hdfs --daemon start journalnode
fi

sleep 8

# ---------------- NAMENODE ----------------

# ACTIVE (node01)
if [[ "$(hostname)" == "node01" ]]; then

    if [ ! -d "/shared/nn/current" ]; then
        echo "Formatting Active NameNode..."
        hdfs namenode -format -force -nonInteractive
    else
        echo "Active NameNode already formatted."
    fi

    hdfs --daemon start namenode
    sleep 8

    echo "Checking ZooKeeper format..."

    /opt/zookeeper/bin/zkCli.sh -server node01:2181 ls /hadoop-ha/project &>/dev/null

    if [ $? -ne 0 ]; then
        echo "Formatting ZK..."
        hdfs zkfc -formatZK -force
    else
        echo "ZK already formatted."
    fi

    hdfs --daemon start zkfc
fi

sleep 5

# STANDBY (node02)
if [[ "$(hostname)" == "node02" ]]; then

    echo "Waiting for node01 NameNode to wake up..."
    # Loop until we can successfully "ping" the port 8420 on node01
    while ! timeout 1s bash -c "true < /dev/tcp/node01/8420" 2>/dev/null; do
        echo "Node 01 is not ready yet... sleeping 2s"
        sleep 2
    done

    echo "Node 01 is UP! Starting bootstrap..."

    if [ ! -d "/shared/nn/current" ]; then
        echo "Bootstrapping Standby NameNode..."
        hdfs namenode -bootstrapStandby -force -nonInteractive
    else
        echo "Standby already bootstrapped."
    fi

    hdfs --daemon start namenode
    sleep 5
    hdfs --daemon start zkfc
fi

sleep 5

# ---------------- DATANODE ----------------

if [[ "$(hostname)" == "node03" || "$(hostname)" == "node04" || "$(hostname)" == "node05" ]]; then
    hdfs --daemon start datanode
fi

sleep 5

# ---------------- YARN ----------------

# RESOURCE MANAGER (node01 Active - node02 Standby)
if [[ "$(hostname)" == "node01" || "$(hostname)" == "node02" ]]; then
    echo "Starting ResourceManager on $(hostname)..."
    yarn --daemon start resourcemanager
fi

sleep 5

# NODE MANAGER (Workers)
if [[ "$(hostname)" == "node03" || "$(hostname)" == "node04" || "$(hostname)" == "node05" ]]; then
    echo "Starting NodeManager on $(hostname)..."
    yarn --daemon start nodemanager
fi

echo "All services started on $(hostname)"

tail -f /dev/null