#!/usr/bin/env bash

set -eux

# invariants
cp -rfp ./bumped-ruby-release/. finalized-release

# finalize
FULL_VERSION=$(awk -F. '{$NF+=1; OFS="."; print $0}' < semver/version)
export FULL_VERSION

pushd finalized-release
  git status
  commits=$(git log --oneline origin/ci..HEAD | wc -l)
  if [[ "$commits" == "0" ]]; then
    :> version-tag/tag-name
    cp semver/version bumped-semver/version
    exit 0
  fi

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

echo "$FULL_VERSION" > bumped-semver/version
echo "v$FULL_VERSION" > version-tag/tag-name
echo "Final release $FULL_VERSION tagged via concourse" > version-tag/annotate-msg
