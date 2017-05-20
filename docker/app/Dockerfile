FROM alphahydrae/lair:latest

LABEL maintainer="docker@alphahydrae.com"

ENV LAIR_LOG_TO_STDOUT="1" \
    RAILS_ENV="production"

ADD etc /etc/

# Expose app
EXPOSE 3000

# Expose serf
EXPOSE 7946
