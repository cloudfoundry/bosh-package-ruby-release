#!/usr/bin/env bash

set -eux

: ${RUBY_VERSION:?}
: ${RUBYGEMS_VERSION:?}
: ${LIBYAML_VERSION:?}

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${BASE_DIR}/bump-helpers.sh"

function main() {
  declare -a versions=(
    "ruby-${RUBY_VERSION}"
    "rubygems-${RUBYGEMS_VERSION}"
    "yaml-${LIBYAML_VERSION}"
  )

  cd bumped-ruby-release
  git clone ../ruby-release .

  set +x
  echo "${PRIVATE_YML}" > config/private.yml
  set -x

  set_git_config "CI Bot" "cf-bosh-eng@pivotal.io"

  for v in "${versions[@]}"
  do
    replace_if_necessary "$v"
    commit_if_changed "Bump package $v"
  done
}

main

