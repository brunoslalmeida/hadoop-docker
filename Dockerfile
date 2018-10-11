FROM sequenceiq/hadoop-docker:2.7.1

LABEL MAINTAINER Prof. Bruno Almeida, Version: 1.0

RUN yum -y --enablerepo=extras install epel-release && \
    yum -y clean all && \
    yum -y install python-pip wget nano vim && \
    yum clean all

RUN pip install google-api-python-client==1.6.4 mrjob==0.5.11