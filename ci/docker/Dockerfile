FROM ubuntu:jammy

COPY --from=bosh/bosh-ecosystem-concourse:latest /usr/local/bin/bosh /usr/local/bin/bosh

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        curl \
        gcc \
        git \
        git-lfs \
        jq \
        libmysqlclient-dev \
        libpq-dev \
        libsqlite3-dev \
        libssl-dev \
        zlib1g-dev

ADD . /tmp/release

RUN set -x && cd /tmp/release && \
    bosh sync-blobs && \
    mkdir -p /var/vcap/packages && mkdir -p /var/vcap/data && \
    for package in $(ls /tmp/release/packages | grep ruby- | grep -v test); do \
        rm -rf /tmp/workspace && \
        mkdir /tmp/workspace && \
        cp -r /tmp/release/src/* /tmp/workspace/ && \
        cp /tmp/release/blobs/* /tmp/workspace && \
        chmod +x /tmp/release/packages/$package/packaging && \
        mkdir -p /var/vcap/packages/$package && \
        cd /tmp/workspace && \
        BOSH_INSTALL_TARGET=/var/vcap/packages/$package /tmp/release/packages/$package/packaging && \
        cd /tmp; \
    done && \
    rm -r /tmp/release /tmp/workspace
