FROM ubuntu
MAINTAINER shimamoto

ENV PIO_VERSION 0.13.0
ENV SPARK_VERSION 2.3.2
ENV HADOOP_VERSION hadoop2.7
ENV ELASTICSEARCH_VERSION 5.6.12
ENV HBASE_VERSION 1.0.0

ENV PIO_HOME /PredictionIO-${PIO_VERSION}
ENV PATH=${PIO_HOME}/bin:$PATH
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

RUN apt-get update \
    && apt-get install -y --auto-remove --no-install-recommends curl git vim openjdk-8-jdk libgfortran3 python \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python get-pip.py \
    && rm get-pip.py

RUN pip install --upgrade pip \
    && pip install setuptools \
    && pip install predictionio

RUN curl -O https://archive.apache.org/dist/predictionio/${PIO_VERSION}/apache-predictionio-${PIO_VERSION}.tar.gz \
    && mkdir /apache-predictionio-${PIO_VERSION} \
    && tar -xvzf apache-predictionio-${PIO_VERSION}.tar.gz -C /apache-predictionio-${PIO_VERSION} \
    && rm apache-predictionio-${PIO_VERSION}.tar.gz \
    && cd apache-predictionio-${PIO_VERSION} \
    && ./make-distribution.sh -Dspark.version=${SPARK_VERSION}

RUN tar zxvf /apache-predictionio-${PIO_VERSION}/PredictionIO-${PIO_VERSION}.tar.gz -C / \
    && rm -r /apache-predictionio-${PIO_VERSION}

RUN mkdir ${PIO_HOME}/vendors
COPY files/pio-env.sh ${PIO_HOME}/conf/pio-env.sh

RUN curl -O https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz \
    && tar -xvzf spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz -C ${PIO_HOME}/vendors \
    && rm spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz

RUN curl -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
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

RUN groupadd -r pio --gid=999 \
    && useradd -r -g pio --uid=999 -m pio \
    && chown -R pio:pio ${PIO_HOME}

USER pio
