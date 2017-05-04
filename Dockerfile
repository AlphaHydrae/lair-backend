FROM alphahydrae/lair-docker-base:latest

# Throw errors if Gemfile has been modified since Gemfile.lock.
RUN bundle config --global frozen 1

# Install dependencies.
WORKDIR /usr/src/app
COPY Gemfile Gemfile.lock /usr/src/app/
RUN bundle install --without development test

# Copy the application.
COPY . /usr/src/app
