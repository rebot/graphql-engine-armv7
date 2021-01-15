FROM ubuntu:18.04
LABEL maintainer="trenson.gilles@gmail.com"

ARG HASURA_VER
ENV HASURA_VER ${HASURA_VER:-1.3.3}
ENV HASURA_ROOT /hasura/
ENV LC_ALL=C.UTF-8
WORKDIR $HASURA_ROOT

# Deps
RUN apt-get update && apt-get install -y libncurses5 git build-essential llvm-9 wget libnuma-dev zlib1g-dev libpq-dev postgresql-client-common postgresql-client libkrb5-dev libssl-dev
RUN wget http://downloads.haskell.org/~ghc/8.10.1/ghc-8.10.1-armv7-deb9-linux.tar.xz && \
    wget http://home.smart-cactus.org/~ben/ghc/cabal-install-3.4.0.0-rc4-armv7l-deb10.tar.xz && \
    tar -xf ghc-8.10.1-armv7-deb9-linux.tar.xz && tar -xf cabal-install-3.4.0.0-rc4-armv7l-deb10.tar.xz && \
    rm *.xz
WORKDIR $HASURA_ROOT/ghc-8.10.1
RUN ./configure && make install
WORKDIR $HASURA_ROOT/
# from https://aur.archlinux.org/cgit/aur.git/plain/ghc_8_10.patch?h=cabal-static
COPY ghc_8_10.patch .
WORKDIR $HASURA_ROOT/cabal-install-3.4.0.0
RUN patch -p1 < ../ghc_8_10.patch
RUN bash ./bootstrap.sh

# graphql-engine
WORKDIR $HASURA_ROOT
RUN git clone -b v$HASURA_VER https://github.com/hasura/graphql-engine.git
WORKDIR graphql-engine/server
RUN /root/.cabal/bin/cabal v2-update
RUN /root/.cabal/bin/cabal v2-build --ghc-options="+RTS -M3G -c -RTS -O0 -j1" -j1
RUN mv `find dist-newstyle/ -type f -name graphql-engine` /srv/

FROM ubuntu:18.04
ENV HASURA_ROOT /hasura/
WORKDIR $HASURA_ROOT/
COPY --from=0 $HASURA_ROOT/graphql-engine/console .
RUN apt-get update && apt-get install -y wget make
RUN wget -O - https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get update && apt-get install -y nodejs python-pip libffi-dev libssl-dev
RUN pip install gsutil
RUN make deps server-build

FROM ubuntu:18.04
LABEL maintainer="trenson.gilles@gmail.com"
ENV HASURA_ROOT /hasura/
COPY --from=0 /srv/graphql-engine /srv/
COPY --from=1 $HASURA_ROOT/static/dist/ /srv/console-assets
RUN apt-get update && apt-get install -y libnuma-dev libpq-dev ca-certificates && apt-get clean
CMD ["/srv/graphql-engine", "serve", "--console-assets-dir", "/srv/console-assets"]
