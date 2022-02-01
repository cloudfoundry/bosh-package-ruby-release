FROM ubuntu:jammy

ADD https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.5.tar.gz /tmp/ruby-2.7.5.tar.gz
ADD https://github.com/ruby/openssl/archive/refs/tags/v3.0.0.tar.gz /tmp/openssl-3.0.0.tar.gz

RUN apt-get update && apt-get install -y build-essential libssl-dev openssl libreadline-dev zlib1g-dev  # rsync

RUN cd /tmp && \
    tar -xf ruby-2.7.5.tar.gz && \
    tar -xf openssl-3.0.0.tar.gz

RUN cp -r /tmp/openssl-3.0.0/ext/openssl /tmp/ruby-2.7.5/ext/ && \
    cp -r /tmp/openssl-3.0.0/lib /tmp/ruby-2.7.5/ext/openssl/

RUN cd /tmp/ruby-2.7.5 && \
    ./configure --with-openssl --with-openssl-dir=/usr/lib/ssl --disable-install-doc --without-gmp && \
    make && \
    make install
