#!/usr/bin/env bash

set -eux

# invariants
cp semver/version bumped-semver/version
cp -rfp ./bumped-ruby-release/. finalized-release

# finalize
FULL_VERSION=$(cat semver/version)
export FULL_VERSION

pushd finalized-release
  git status

  set +x
  echo "${PRIVATE_YML}" > config/private.yml
  set -x

  bosh create-release --tarball=/tmp/ruby-release.tgz --timestamp-version --force
  bosh finalize-release --version "$FULL_VERSION" /tmp/ruby-release.tgz

  git add -A
  git status

  git config user.name "CI Bot"
  git config user.email "cf-bosh-eng@pivotal.io"

  git commit -m "Adding final release $FULL_VERSION via concourse"
popd

echo "v${FULL_VERSION}" > version-tag/tag-name
echo "Final release ${FULL_VERSION} tagged via concourse" > version-tag/annotate-msg
