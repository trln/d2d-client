FROM ruby:2.7 AS base

RUN apt-get update && apt-get -y upgrade

FROM base AS builder

RUN mkdir /build

COPY Gemfile d2d-client.gemspec VERSION /build

WORKDIR /build

RUN bundle config set path /gems && bundle install

FROM base

COPY --from=builder /gems /gems

RUN bundle config set path /gems 

CMD ["/bin/bash"]





