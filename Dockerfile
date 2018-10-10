FROM sequenceiq/hadoop-docker:2.7.1

LABEL MAINTAINER Prof. Bruno Almeida, Version: 1.0

RUN yum -y --enablerepo=extras install epel-release && \
    yum -y clean all && \
    yum -y install python-pip wget nano vim && \
    yum clean all

RUN pip install google-api-python-client==1.6.4 mrjob==0.5.11

ENV SQOOP_SERVER_EXTRA_LIB /var/lib/sqoop2
ENV PATH $PATH:$SQOOP_SERVER_EXTRA_LIB/bin

ENV HADOOP_COMMON_HOME /usr/local/hadoop/share/hadoop/common
ENV HADOOP_HDFS_HOME /usr/local/hadoop/share/hadoop/hdfs
ENV HADOOP_MAPRED_HOME /usr/local/hadoop/share/hadoop/mapreduce
ENV HADOOP_YARN_HOME /usr/local/hadoop/share/hadoop/yarn
ENV HADOOP_CONF_HOME /usr/local/hadoop/etc/hadoop
ENV HADOOP_HOME /usr/local/hadoop

RUN wget http://ftp.unicamp.br/pub/apache/sqoop/1.99.7/sqoop-1.99.7-bin-hadoop200.tar.gz && \
    tar -zxvf sqoop-1.99.7-bin-hadoop200.tar.gz && \
    mv sqoop-1.99.7-bin-hadoop200 $SQOOP_SERVER_EXTRA_LIB/ && \
    rm sqoop-1.99.7-bin-hadoop200.tar.gz && \
    sed -i 's/\/etc\/hadoop\/conf\//\/usr\/local\/hadoop\/etc\/hadoop\//g' $SQOOP_SERVER_EXTRA_LIB/conf/sqoop.properties && \
    sed -i 's/allowed.system.users=##/allowed.system.users=sqoop2##/g' $HADOOP_CONF_HOME/container-executor.cfg &&\
    sed -i "s/<\/property>/<\/property><property> <name>hadoop.proxyuser.sqoop2.hosts<\/name><value>*<\/value><\/property><property><name>hadoop.proxyuser.sqoop2.groups<\/name><value>*<\/value><\/property>/g" $HADOOP_CONF_HOME/core-site.xml && \
    wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.47.tar.gz && \
    tar -zxvf mysql-connector-java-5.1.47.tar.gz && \
    cp mysql-connector-java-5.1.47/mysql-connector-java-5.1.47-bin.jar $SQOOP_SERVER_EXTRA_LIB && \
    rm -rf mysql-connector-java-5.1.47*