FROM alphahydrae/lair-docker-base:1.0.0

# Throw errors if Gemfile has been modified since Gemfile.lock.
RUN bundle config --global frozen 1

# Install dependencies.
WORKDIR /usr/src/app
COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
RUN bundle install --without development test

# Copy the application.
COPY . /usr/src/app

# Add the container initialization script.
ADD docker/base/init.sh /etc/cont-init.d/

# Expose the application.
EXPOSE 3000

# Expose serf.
EXPOSE 7946
