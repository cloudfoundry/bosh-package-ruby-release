#!/bin/bash

set -eux -o pipefail

dir=$(mktemp -d)

mkdir -p "${dir}"
pushd "${dir}"

wget -O ruby-2.7.5.tar.gz https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.5.tar.gz
wget -O openssl-3.0.0.tar.gz https://github.com/ruby/openssl/archive/refs/tags/v3.0.0.tar.gz

tar -xf ruby-2.7.5.tar.gz
tar -xf openssl-3.0.0.tar.gz

cp -r openssl-3.0.0/ext/openssl ruby-2.7.5/ext/
cp -r openssl-3.0.0/lib ruby-2.7.5/ext/openssl/

tar -czf ruby-2.7.5-openssl-3.0.0.tar.gz ruby-2.7.5

popd

bosh add-blob "${dir}/ruby-2.7.5-openssl-3.0.0.tar.gz" ruby-2.7.5.tar.gz

rm -r "${dir}"
