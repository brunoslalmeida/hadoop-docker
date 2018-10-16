# Criando hadoop 2.9.1 pseudo distribuido
# Este Dockerfile foi baseado no Sequenceiq/hadoop-docker
FROM tianon/centos:6.5

LABEL MAINTAINER Prof. Bruno Almeida (https://aquelatecnologia.com.br)
LABEL Version: 1.0

ENV HADOOP_PREFIX /usr/local/hadoop
#ENV HADOOP_COMMON_HOME /usr/local/hadoop
#ENV HADOOP_HDFS_HOME /usr/local/hadoop
#ENV HADOOP_MAPRED_HOME /usr/local/hadoop
#ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop

ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop
ENV SQOOP_SERVER_EXTRA_LIB /var/lib/sqoop2
ENV JAVA_HOME /usr/lib/jvm/jre-1.7.0-openjdk.x86_64

ENV BOOTSTRAP /etc/bootstrap.sh

ENV PATH $PATH:$HADOOP_PREFIX/bin:$SQOOP_SERVER_EXTRA_LIB/bin

USER root

#Instalando DEPS
RUN yum -y install --enablerepo=extras epel-release; \
    yum -y clean all; \
    yum -y install curl which tar \
                   sudo openssh-server openssh-clients \
                   rsync python-pip wget \
                   nano vim python-pip \
                   java-1.7.0-openjdk; \
    yum -y update libselinux; 

RUN rpm --rebuilddb; 

RUN pip install google-api-python-client==1.6.4 mrjob==0.5.11

# passwordless ssh
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

#Baixando HADOOP
ARG HADOOP_VERSION=2.9.1
RUN curl -s http://www.eu.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz | tar -xz -C /usr/local/
RUN ln -s ./hadoop-$HADOOP_VERSION $HADOOP_PREFIX

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/jre-1.7.0-openjdk.x86_64\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

## Criando pasta input no HDFS
RUN mkdir $HADOOP_PREFIX/input
RUN cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input

## Configurando para pseduo distribuido
ADD /etc/hadoop/core-site.xml $HADOOP_PREFIX/etc/hadoop/core-site.xml.template
RUN sed s/HOSTNAME/localhost/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
ADD /etc/hadoop/hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

ADD /etc/hadoop/mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD /etc/hadoop/yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

RUN $HADOOP_PREFIX/bin/hdfs namenode -format

ADD /etc/ssh/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config

# workingaround docker.io build error
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh
RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "Port 2122" >> /etc/ssh/sshd_config


# Isto é necessário para o SQOOP
ENV HADOOP_HOME /usr/local/hadoop

#http://sqoop.apache.org/docs/1.99.7/admin/Installation.html
#If the environment $HADOOP_HOME is set, Sqoop will usee the following locations: 
#$HADOOP_HOME/share/hadoop/common, 
#$HADOOP_HOME/share/hadoop/hdfs, 
#$HADOOP_HOME/share/hadoop/mapreduce and 
#$HADOOP_HOME/share/hadoop/yarn.

##Instalando Sqoop
RUN wget http://www.eu.apache.org/dist/sqoop/1.99.7/sqoop-1.99.7-bin-hadoop200.tar.gz ; \
    tar -zxvf sqoop-1.99.7-bin-hadoop200.tar.gz ; \
    mv sqoop-1.99.7-bin-hadoop200 /var/lib ; \
    ln -s /var/lib/sqoop-1.99.7-bin-hadoop200 $SQOOP_SERVER_EXTRA_LIB; \
    rm sqoop-1.99.7-bin-hadoop200.tar.gz ; \
    sed -i 's/\/etc\/hadoop\/conf\//\/usr\/local\/hadoop\/etc\/hadoop\//g' $SQOOP_SERVER_EXTRA_LIB/conf/sqoop.properties ; \
    sed -i 's/allowed.system.users=##/allowed.system.users=root##/g' $HADOOP_CONF_DIR/container-executor.cfg 

#Instalando conector mysql para o Sqoop
RUN wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.47.tar.gz ; \
    tar -zxvf mysql-connector-java-5.1.47.tar.gz ; \
    cp mysql-connector-java-5.1.47/mysql-connector-java-5.1.47-bin.jar $SQOOP_SERVER_EXTRA_LIB ; \
    rm -rf mysql-connector-java-5.1.47*;

RUN service sshd start && \
    $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && \
    $HADOOP_PREFIX/sbin/start-dfs.sh && \
    $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/root && \    
    $HADOOP_PREFIX/bin/hdfs dfs -put $HADOOP_PREFIX/etc/hadoop/ input

ADD /etc/bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

CMD ["/etc/bootstrap.sh", "-d"]

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090

# Mapred ports
EXPOSE 19888

#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088

#Other ports
EXPOSE 49707 2122   