FROM postgres:9.5

LABEL maintainer="docker@alphahydrae.com"

COPY load-dump /usr/local/bin/
COPY init-scripts /docker-entrypoint-initdb.d
