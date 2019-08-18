# Criando hadoop 2.9.1 pseudo distribuido
# Este Dockerfile foi baseado no Sequenceiq/hadoop-docker
FROM ubuntu:xenial

LABEL MAINTAINER Prof. Bruno Almeida <bruno@aquelatecnologia.com.br> (https://aquelatecnologia.com.br)
LABEL Version: 1.0

ENV HADOOP_HOME /usr/local/hadoop
ENV HADOOP_PREFIX $HADOOP_HOME
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop
ENV HADOOP_CONF_DIR $HADOOP_PREFIX/etc/hadoop
ENV JAVA_HOME /usr/lib/jvm/default-java

ENV BOOTSTRAP /etc/bootstrap.sh

ARG HADOOP_VERSION=2.9.2

ENV PATH $PATH:$HADOOP_PREFIX/bin:$SQOOP_SERVER_EXTRA_LIB/bin

RUN apt-get update

RUN apt-get -y install \
        curl tar openssh-server \
        openssh-client python-pip rsync \
        wget nano vim default-jdk

RUN pip install google-api-python-client==1.6.4 mrjob==0.5.11;

RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key; \
    ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key; \
    ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa; \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

RUN wget http://www.eu.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz; \
    tar -zxf hadoop-$HADOOP_VERSION.tar.gz ; \
    mv hadoop-$HADOOP_VERSION $HADOOP_HOME ; \
    rm -rf hadoop-$HADOOP_VERSION.tar.gz;

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/default-java\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

ADD /etc/hadoop/core-site.xml $HADOOP_PREFIX/etc/hadoop/core-site.xml.template
RUN sed s/HOSTNAME/localhost/ $HADOOP_PREFIX/etc/hadoop/core-site.xml.template > $HADOOP_PREFIX/etc/hadoop/core-site.xml
ADD /etc/hadoop/hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

ADD /etc/hadoop/mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD /etc/hadoop/yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

RUN $HADOOP_PREFIX/bin/hdfs namenode -format

ADD /etc/ssh/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config

# workingaround docker.io build error
RUN ls -la $HADOOP_PREFIX/etc/hadoop/*-env.sh
RUN chmod +x $HADOOP_PREFIX/etc/hadoop/*-env.sh
RUN ls -la $HADOOP_PREFIX/etc/hadoop/*-env.sh

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "Port 2122" >> /etc/ssh/sshd_config

ADD /etc/bootstrap.sh /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh

RUN mkdir -p /sample/java; \
    mkdir -p /sample/python; \
    mkdir -p /sample/loremipsum; \
    cd /sample/java; \
    wget https://raw.githubusercontent.com/aquelatecnologia/desafio-hadoop/master/exemplos/wordcount/java/WordCount.java; \
    cd /sample/python; \
    wget https://raw.githubusercontent.com/aquelatecnologia/desafio-hadoop/master/exemplos/wordcount/python/wordcount.py;
ADD /lorem-ipsum.txt /sample/loremipsum/lorem-ipsum.txt

CMD ["/etc/bootstrap.sh", "-d" ]

EXPOSE 50010 50020 50070 50075 50090 19888 8030 8031 8032 
EXPOSE 8033 8040 8042 8088 49707 2122   
