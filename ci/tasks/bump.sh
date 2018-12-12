#!/usr/bin/env bash

set -eux

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${script_dir}/bump-helpers.sh

cd bumped-ruby-release

git clone ../ruby-release .

set +x
echo "${PRIVATE_YML}" > config/private.yml
set -x

git config user.name "CI Bot"
git config user.email "cf-bosh-eng@pivotal.io"

replace_if_necessary 2.4 ruby
replace_if_necessary 2.4 rubygems
replace_if_necessary 2.4 yaml

if [[ "$( git status --porcelain )" != "" ]]; then
  git commit -am "Bump ruby 2.4"
fi
