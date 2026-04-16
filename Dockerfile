# syntax=docker/dockerfile:1

# Base: install runtime and build dependencies
FROM ruby:3.4.5-slim-bookworm AS base

RUN apt-get update -qq && \
    apt-get install -yq --no-install-recommends \
      libpq5 \
      libjemalloc2 \
      postgresql-client \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

WORKDIR /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

# Build: install gems
FROM base AS build

RUN apt-get update -qq && \
    apt-get install -yq --no-install-recommends \
      build-essential \
      libpq-dev \
      libhiredis-dev \
      pkg-config \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

RUN cp config/deploy.yml config/deploy.yml.bak 2>/dev/null || true

# Precompile bootsnap for faster boot
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Final: minimal image with only runtime deps
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN chown -R rails:rails /rails

# Enable jemalloc
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

USER rails

EXPOSE 3000

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bin/rails", "server"]
