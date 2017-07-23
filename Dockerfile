FROM alphahydrae/lair-docker-base:1.1.0

ENV LAIR_LOG_TO_STDOUT="1" \
    RAILS_ENV="production"

# Throw errors if Gemfile has been modified since Gemfile.lock.
RUN bundle config --global frozen 1

# Install dependencies.
WORKDIR /usr/src/app
COPY Gemfile Gemfile.lock /usr/src/app/
RUN bundle install --without development test

# Copy the application.
COPY . /usr/src/app
