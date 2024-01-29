#!/usr/bin/env bash

set -eux pipefail

export FULL_VERSION=$(cat semver/version)
pushd ruby-release
  commits=$(git rev-list HEAD ^origin/main --pretty=oneline --count)
  if [[ "$commits" == "0" ]]; then
    exit 0
  fi

  # finalize
  git status

  set +x
  echo "$PRIVATE_YML" > config/private.yml
  set -x

  bosh create-release --tarball=/tmp/ruby-release.tgz --timestamp-version --force
  bosh finalize-release --version "$FULL_VERSION" /tmp/ruby-release.tgz

  git add -A
  git status

  git config user.name "CI Bot"
  git config user.email "cf-bosh-eng@pivotal.io"

  git commit -m "Adding final release $FULL_VERSION via concourse"
popd
