FROM alpine:3.8
MAINTAINER shimamoto

ENV PIO_VERSION 0.14.0
ENV SPARK_VERSION 2.4.0
ENV HADOOP_VERSION hadoop2.7
ENV ELASTICSEARCH_VERSION 6.6.2
ENV HBASE_VERSION 1.2.11

ENV PIO_HOME /PredictionIO-${PIO_VERSION}
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH=${PIO_HOME}/bin:${JAVA_HOME}/bin:$PATH

RUN apk add --no-cache curl bash git vim openjdk8 python3 py-pip \
    && pip install --upgrade pip \
    && pip install setuptools \
    && pip install predictionio

RUN curl -O https://archive.apache.org/dist/predictionio/${PIO_VERSION}/apache-predictionio-${PIO_VERSION}.tar.gz \
    && mkdir /apache-predictionio-${PIO_VERSION} \
    && tar -xvzf apache-predictionio-${PIO_VERSION}.tar.gz -C /apache-predictionio-${PIO_VERSION} \
    && rm apache-predictionio-${PIO_VERSION}.tar.gz \
    && ./apache-predictionio-${PIO_VERSION}/make-distribution.sh -Dspark.version=${SPARK_VERSION} -Delasticsearch.version=${ELASTICSEARCH_VERSION} -Dhbase.version=${HBASE_VERSION} \
    && tar zxvf /apache-predictionio-${PIO_VERSION}/PredictionIO-${PIO_VERSION}.tar.gz -C / \
    && rm -r /apache-predictionio-${PIO_VERSION} \
    && rm -r /root/.ivy2 \
    && mkdir ${PIO_HOME}/vendors \
    && curl -O https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz \
    && tar -xvzf spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz -C ${PIO_HOME}/vendors \
    && rm spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz \
    && curl -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
    && tar -xvzf elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz -C ${PIO_HOME}/vendors \
    && rm elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
    && echo 'cluster.name: predictionio' >> ${PIO_HOME}/vendors/elasticsearch-${ELASTICSEARCH_VERSION}/config/elasticsearch.yml \
    && echo 'network.host: 127.0.0.1' >> ${PIO_HOME}/vendors/elasticsearch-${ELASTICSEARCH_VERSION}/config/elasticsearch.yml \
    && curl -O http://archive.apache.org/dist/hbase/hbase-${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz \
    && tar -xvzf hbase-${HBASE_VERSION}-bin.tar.gz -C ${PIO_HOME}/vendors \
    && rm hbase-${HBASE_VERSION}-bin.tar.gz

COPY files/pio-env.sh ${PIO_HOME}/conf/pio-env.sh
COPY files/hbase-site.xml ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml

RUN sed -i "s|VAR_PIO_HOME|${PIO_HOME}|" ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml \
    && sed -i "s|VAR_HBASE_VERSION|${HBASE_VERSION}|" ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml \
    && addgroup pio \
    && adduser -D pio -G pio \
    && chown -R pio:pio ${PIO_HOME}

USER pio
