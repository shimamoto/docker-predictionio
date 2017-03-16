# docker-predictionio
Docker container for PredictionIO-based machine learning services

This container uses Apache Spark, HBase and Elasticsearch.
The PredictionIO version is [jpioug](https://github.com/jpioug) version.

### Use it interactively for development:
1. First, build docker image from local Dockerfile: cd to the path containing the Dockerfile, then:
```Bash
$ docker build -t predictionio .
```
then:
```Bash
$ docker run -p 8000:8000 --name predictionio_instance -it predictionio /bin/bash
```

2. Then in docker container, start all services and check they are started
```Bash
$ pio-start-all
$ jps -l
```
