#!/usr/bin/env bash

set -eux

RUBY_VERSION=2.4
RUBYGEMS_VERSION=2.7
LIBYAML_VERSION=0.1

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${script_dir}/bump-helpers.sh

cd bumped-ruby-release

git clone ../ruby-release .

set +x
echo "${PRIVATE_YML}" > config/private.yml
set -x

git config user.name "CI Bot"
git config user.email "cf-bosh-eng@pivotal.io"

replace_if_necessary "${RUBY_VERSION}" ruby

if [[ "$( git status --porcelain )" != "" ]]; then
  git commit -am "Bump ruby ${RUBY_VERSION}"
fi

replace_if_necessary "${RUBYGEMS_VERSION}" rubygems

if [[ "$( git status --porcelain )" != "" ]]; then
  git commit -am "Bump rubygems ${RUBYGEMS_VERSION}"
fi

replace_if_necessary "${LIBYAML_VERSION}" yaml

if [[ "$( git status --porcelain )" != "" ]]; then
  git commit -am "Bump libyaml ${LIBYAML_VERSION}"
fi
