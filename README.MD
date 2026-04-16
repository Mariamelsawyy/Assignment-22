# 🐘 Hadoop High Availability Cluster with YARN & ZooKeeper

<img width="935" height="686" alt="Image" src="https://github.com/user-attachments/assets/b71e4a28-5b4b-4c36-89b6-a290919542ee" />

## Project Overview

This project demonstrates the implementation of a **production-style Hadoop cluster** with:

- HDFS High Availability (HA)
- YARN High Availability
- ZooKeeper-based automatic failover
- JournalNode quorum mechanism
- MapReduce execution on YARN
- Docker-based automation

The cluster eliminates single points of failure and ensures distributed storage and processing reliability.

---

# Architecture Justification

## Two NameNodes  
**Purpose: HDFS High Availability**

- Prevent single point of failure
- Automatic failover using ZooKeeper
- Continuous metadata availability

## Three JournalNodes  
**Purpose: Prevent Split-Brain & Maintain Consistency**

- Store edit logs
- Quorum-based majority (2 out of 3)
- Strong metadata consistency during failover

## Two ResourceManagers  
**Purpose: YARN High Availability**

- Prevent YARN single point of failure
- Active/Standby failover support
- Continuous job scheduling availability

## Three DataNodes  
**Purpose: Data Replication & Fault Tolerance**

- Replication factor = 3
- Data remains available even if one node fails

## Three NodeManagers  
**Purpose: Distributed Processing**

- Parallel computation
- Improved data locality
- Distributed container execution

## Three ZooKeeper Nodes  
**Purpose: Coordination & Automatic Failover**

- Achieve quorum (majority = 2)
- Reliable leader election
- Avoid split-brain scenarios

---

# Installation & Setup

---

## A) Install Java

```bash
apt install -y openjdk-11-jdk
```

---

## B) Download & Install Hadoop

```bash
wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
tar -xvzf hadoop-3.3.6.tar.gz
mv hadoop-3.3.6 /opt/hadoop
rm hadoop-3.3.6.tar.gz
```
---

## C) Start JournalNode

```bash
hdfs --daemon start journalnode
```
---

## D) Format First NameNode

```bash
hdfs namenode -format
```
---

## E) Bootstrap Standby NameNode

```bash
hdfs namenode -bootstrapStandby
```
---

## F) Configure SSH Between Nodes

```bash
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -q -N ""
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 600 /root/.ssh/id_rsa
```

### Test Connectivity

```bash
ssh root@node02
```
---

## G) Install ZooKeeper

```bash
cd /opt
wget https://downloads.apache.org/zookeeper/zookeeper-3.9.4/apache-zookeeper-3.9.4-bin.tar.gz
tar -xzvf apache-zookeeper-3.9.4-bin.tar.gz
mv apache-zookeeper-3.9.4-bin /opt/zookeeper
rm apache-zookeeper-3.9.4-bin.tar.gz
```

### Configure ZooKeeper

```bash
mkdir -p /opt/data/zookeeper
echo "1" > /opt/data/zookeeper/myid
chown -R root:root /opt/data/zookeeper
chmod -R 755 /opt/data/zookeeper
```

### Edit zoo.cfg

```bash
tickTime=2000
dataDir=/opt/data/zookeeper
clientPort=2181
initLimit=5
syncLimit=2
server.1=node01:2888:3888
server.2=node02:2888:3888
server.3=node03:2888:3888
```

### Start ZooKeeper

```bash
/opt/zookeeper/bin/zkServer.sh start
```
---

## H) Enable Automatic Failover

```bash
hdfs zkfc -formatZK
hdfs --daemon start zkfc
```

## Testing High Availability

### Test NameNode HA

```bash
hdfs haadmin -getServiceState nn1
hdfs haadmin -getServiceState nn2
```

### Test ResourceManager HA

```bash
yarn rmadmin -getServiceState rm1
yarn rmadmin -getServiceState rm2
```
---

## I) Running MapReduce on YARN

### Prepare Input

```bash
hdfs dfs -mkdir -p /input
hdfs dfs -put /home/test_file /input/
hdfs dfs -ls /input/
```
---

### Run WordCount Example

```bash
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar wordcount /input /output
```
---

## Results Achieved

- NameNode HA working (Active/Standby)

- ZooKeeper quorum working

- JournalNodes operational

- ResourceManager HA working

- Data replication factor = 3 verified

- Failover tested successfully

- MapReduce executed on YARN

- Custom Java MapReduce job executed

- Data ingestion verified

---

## Automation

- There is a **`start.sh`** script that automatically starts all required services.

- There is a **`Dockerfile`** used to facilitate the installation and preparation of the environment.

---

## How to Start the Cluster

### Start the Machines
Run the following command:

```bash
docker compose up
```
### If You Don't Want the Containers to Start Automatically 

#### Change on docker-compose file :

```yaml
command: bash /start.sh
```

#### To :

```yaml
command: sleep infinity
```
---

## References

Hadoop Official Documentation

- **Environment Preparation**  
  https://hadoop.apache.org/docs/r3.3.0/hadoop-project-dist/hadoop-common/SingleCluster.html#Prerequisites

- **NameNode and JournalNode Setup**  
  https://hadoop.apache.org/docs/r3.3.0/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html#Configuration_details

- **Zookeeper and Automatic Failover**  
  https://hadoop.apache.org/docs/r3.3.0/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html#Automatic_Failover

- **SSH Configuration (Passphraseless SSH)**  
  https://hadoop.apache.org/docs/r3.3.0/hadoop-project-dist/hadoop-common/SingleCluster.html#Setup_passphraseless_ssh

- **ResourceManager Setup**  
  https://hadoop.apache.org/docs/r3.3.0/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html#Deployment

- **MapReduce Configuration (mapred-site.xml)**  
  https://hadoop.apache.org/docs/r3.3.0/hadoop-project-dist/hadoop-common/SingleCluster.html#YARN_on_a_Single_Node

- **DataNode Configuration**  
  https://hadoop.apache.org/docs/r3.3.0/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml













