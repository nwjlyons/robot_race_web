###
### Fist Stage - Building the Release
###
# https://hub.docker.com/r/hexpm/elixir/tags
ARG TARGETPLATFORM
FROM --platform=$TARGETPLATFORM hexpm/elixir:1.20.0-rc.1-erlang-28.3.1-ubuntu-jammy-20260109 AS build

# install build dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential npm git libncurses6 libtinfo6 \
    && rm -rf /var/lib/apt/lists/*

# prepare build dir
WORKDIR /app

# extend hex timeout
ENV HEX_HTTP_TIMEOUT=20

# install hex + rebar (already available in base image)

# set build ENV as prod
ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=nokey

# Copy over the mix.exs and mix.lock files to load the dependencies. If those
# files don't change, then we don't keep re-fetching and rebuilding the deps.
COPY mix.exs mix.lock ./
COPY config config

RUN mix deps.get --only prod && \
    mix deps.compile

RUN mix docs

# install npm dependencies
#COPY assets/package.json assets/package-lock.json ./assets/
#RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY priv priv
COPY assets assets
COPY lib lib

# build assets
#RUN npm run --prefix ./assets deploy
RUN mix assets.deploy

# compile and build release
COPY rel rel
RUN mix do compile, release

###
### Second Stage - Setup the Runtime Environment
###

# prepare release docker image
ARG TARGETPLATFORM
FROM --platform=$TARGETPLATFORM hexpm/elixir:1.20.0-rc.1-erlang-28.3.1-ubuntu-jammy-20260109 AS app
RUN apt-get update \
    && apt-get install -y --no-install-recommends libstdc++6 openssl libncurses6 libtinfo6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN chown -R nobody:nogroup /app

USER nobody

COPY --from=build --chown=nobody:nogroup /app/_build/prod/rel/robot_race_web ./

ENV HOME=/app
ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=nokey
ENV PORT=4000

CMD ["bin/robot_race_web", "start"]
