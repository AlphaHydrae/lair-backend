FROM ruby:2.3

LABEL maintainer="docker@alphahydrae.com"

# Install GnuPG & the PostgreSQL client
RUN apt-get update -q -y \
    && apt-get install -q -y --no-install-recommends cron gnupg postgresql-client

# Install dumb init
ENV DUMB_INIT_VERSION="1.2.0"
ADD https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

# Install the backup gem
WORKDIR /usr/src/app
ADD Gemfile Gemfile.lock /usr/src/app/
RUN bundle install

# Initialize GnuPG
RUN gpg --list-keys

# Clean up
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set up cron
RUN mkdir -p /etc/cron.d /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /var/log \
    && rm -f /etc/cron.d/* \
    && rm -f /etc/cron.hourly/* \
    && rm -f /etc/cron.daily/* \
    && rm -f /etc/cron.weekly/* \
    && rm -f /etc/cron.monthly/*

# Add backup configuration
ADD config.rb /backup/
ADD models /backup/models

# Add scripts
ADD backup cron /usr/local/bin/

# Add backup script to crontab
RUN echo "* * * * * /usr/local/bin/backup" | crontab -

# Run cron
ENTRYPOINT [ "/usr/local/bin/dumb-init" ]
CMD [ "/usr/local/bin/cron" ]
