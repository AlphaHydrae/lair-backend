FROM alphahydrae/lair-docker-base

# Throw errors if Gemfile has been modified since Gemfile.lock.
RUN bundle config --global frozen 1

# Install dependencies.
WORKDIR /usr/src/app
COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
RUN bundle install --without development test

# Copy the application.
COPY . /usr/src/app

# Install serf.
RUN mkdir /opt/bin && \
    gunzip -c docker/serf/serf_0.7.0_linux_amd64.zip > /opt/bin/serf && \
    chmod 755 /opt/bin/serf && \
    rm -f /tmp/serf.gz

EXPOSE 3000
EXPOSE 7946

CMD [ "./docker/bin/start-app.sh" ]
