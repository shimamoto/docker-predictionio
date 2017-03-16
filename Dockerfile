FROM ubuntu
MAINTAINER shimamoto

ENV PIO_VERSION 0.11.0-v1-SNAPSHOT
ENV SPARK_VERSION 1.6.3
ENV ELASTICSEARCH_VERSION 1.7.6
ENV HBASE_VERSION 1.0.0

ENV PIO_HOME /PredictionIO-${PIO_VERSION}
ENV PATH=${PIO_HOME}/bin:$PATH
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

RUN apt-get update \
    && apt-get install -y --auto-remove --no-install-recommends curl git openjdk-8-jdk libgfortran3 python-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN cd / \
    && git clone https://github.com/jpioug/incubator-predictionio.git \
    && cd incubator-predictionio \
    && ./make-distribution.sh

RUN tar zxvf /incubator-predictionio/PredictionIO-${PIO_VERSION}.tar.gz -C /
RUN rm -r /incubator-predictionio
RUN mkdir /${PIO_HOME}/vendors
COPY files/pio-env.sh ${PIO_HOME}/conf/pio-env.sh

RUN curl -O http://d3kbcqa49mib13.cloudfront.net/spark-${SPARK_VERSION}-bin-hadoop2.6.tgz \
    && tar -xvzf spark-${SPARK_VERSION}-bin-hadoop2.6.tgz -C ${PIO_HOME}/vendors \
    && rm spark-${SPARK_VERSION}-bin-hadoop2.6.tgz

RUN curl -O https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
    && tar -xvzf elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz -C ${PIO_HOME}/vendors \
    && rm elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
    && echo 'cluster.name: predictionio' >> ${PIO_HOME}/vendors/elasticsearch-${ELASTICSEARCH_VERSION}/config/elasticsearch.yml \
    && echo 'network.host: 127.0.0.1' >> ${PIO_HOME}/vendors/elasticsearch-${ELASTICSEARCH_VERSION}/config/elasticsearch.yml

RUN curl -O http://archive.apache.org/dist/hbase/hbase-${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz \
    && tar -xvzf hbase-${HBASE_VERSION}-bin.tar.gz -C ${PIO_HOME}/vendors \
    && rm hbase-${HBASE_VERSION}-bin.tar.gz
COPY files/hbase-site.xml ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml
RUN sed -i "s|VAR_PIO_HOME|${PIO_HOME}|" ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml \
    && sed -i "s|VAR_HBASE_VERSION|${HBASE_VERSION}|" ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml
