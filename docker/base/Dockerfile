FROM ruby:2.2

RUN apt-get update -y
RUN apt-get install -y imagemagick nodejs postgresql-client --no-install-recommends
RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
RUN bundle install --without development test
