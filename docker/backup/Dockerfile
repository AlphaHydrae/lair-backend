FROM ruby:2.3

LABEL maintainer="docker@alphahydrae.com"

# Install GnuPG & the PostgreSQL client.
RUN apt-get update -q -y \
    && apt-get install -q -y --no-install-recommends lsb-release \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list \
    && wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add - \
    && apt-get update -q -y \
    && apt-get install -q -y --no-install-recommends gnupg postgresql-client

# Install the backup gem.
WORKDIR /usr/src/app
ADD Gemfile Gemfile.lock /usr/src/app/
RUN bundle install

# Initialize GnuPG.
RUN gpg --list-keys

# Clean up.
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add backup configuration.
ADD config.rb /backup/
ADD models /backup/models

# Set backup as the entrypoint.
ENTRYPOINT [ "/usr/local/bundle/bin/backup" ]
CMD [ "perform", "--trigger", "lair", "--config-file", "/backup/config.rb", "--root-path", "/var/lib/lair/backup", "--data-path", "data", "--log-path", "log", "--tmp-path", "tmp" ]
