FROM ubuntu:24.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt update && apt install -y \
    openjdk-11-jdk \
    ssh \
    rsync \
    wget \
    pdsh \
    curl \
    nano \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin

# Download Hadoop
RUN wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz \
    && tar -xvzf hadoop-3.3.6.tar.gz \
    && mv hadoop-3.3.6 /opt/hadoop \
    && rm hadoop-3.3.6.tar.gz

# Download ZooKeeper
# Download ZooKeeper 3.9.5 (Latest Stable)
RUN cd /opt && \
    wget https://downloads.apache.org/zookeeper/zookeeper-3.9.5/apache-zookeeper-3.9.5-bin.tar.gz && \
    tar -xzvf apache-zookeeper-3.9.5-bin.tar.gz && \
    mv apache-zookeeper-3.9.5-bin /opt/zookeeper && \
    rm apache-zookeeper-3.9.5-bin.tar.gz

# Create necessary directories
RUN mkdir -p /opt/data/zookeeper && \
    mkdir -p /opt/hadoop/logs && \
    chown -R root:root /opt/data/zookeeper /opt/hadoop/logs && \
    chmod -R 755 /opt/data/zookeeper /opt/hadoop/logs

# Create zoo.cfg automatically
RUN cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg && \
    echo "tickTime=2000" >> /opt/zookeeper/conf/zoo.cfg && \
    echo "dataDir=/opt/data/zookeeper" >> /opt/zookeeper/conf/zoo.cfg && \
    echo "clientPort=2181" >> /opt/zookeeper/conf/zoo.cfg && \
    echo "initLimit=5" >> /opt/zookeeper/conf/zoo.cfg && \
    echo "syncLimit=2" >> /opt/zookeeper/conf/zoo.cfg && \
    echo "server.1=node01:2888:3888" >> /opt/zookeeper/conf/zoo.cfg && \
    echo "server.2=node02:2888:3888" >> /opt/zookeeper/conf/zoo.cfg && \
    echo "server.3=node03:2888:3888" >> /opt/zookeeper/conf/zoo.cfg

# Set Hadoop Environment
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV HADOOP_MAPRED_HOME=$HADOOP_HOME


# Add JAVA_HOME and classpath settings inside Hadoop configs
RUN echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/yarn-env.sh && \
    echo "export HADOOP_CLASSPATH=\$HADOOP_CLASSPATH:\$HADOOP_HOME/etc/hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HADOOP_OPTS=\"\$HADOOP_OPTS -Dlog4j.configuration=file:\$HADOOP_HOME/etc/hadoop/log4j.properties\"" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# Export to bashrc
RUN echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc && \
    echo "export HADOOP_HOME=$HADOOP_HOME" >> ~/.bashrc && \
    echo "export HADOOP_CONF_DIR=$HADOOP_CONF_DIR" >> ~/.bashrc && \
    echo "export HADOOP_MAPRED_HOME=$HADOOP_HOME" >> ~/.bashrc && \
    echo "export HADOOP_YARN_HOME=$HADOOP_HOME" >> ~/.bashrc && \
    echo "export HADOOP_LOG_DIR=$HADOOP_LOG_DIR" >> ~/.bashrc && \
    echo "export HADOOP_CLASSPATH=\$HADOOP_HOME/etc/hadoop:\$HADOOP_CLASSPATH" >> ~/.bashrc

WORKDIR /root