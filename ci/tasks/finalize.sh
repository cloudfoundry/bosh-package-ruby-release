#!/usr/bin/env bash

set -eux

# invariants
cp -rfp ./ruby-release/. finalized-release

pushd finalized-release
  commits=$(git log --oneline origin/ci..HEAD | wc -l)
  if [[ "$commits" == "0" ]]; then
    :> ../version-tag/tag-name #prevent git-resource to tag HEAD
    :> ../version-tag/annotate-msg
    exit 0
  fi
popd

# finalize
full_version=$( cat semver/version )

pushd finalized-release
  git status

  set +x
  echo "$PRIVATE_YML" > config/private.yml
  set -x

  bosh create-release --tarball=/tmp/ruby-release.tgz --timestamp-version --force
  bosh finalize-release --version "$full_version" /tmp/ruby-release.tgz

  git add -A
  git status

  git config user.name "CI Bot"
  git config user.email "cf-bosh-eng@pivotal.io"

  git commit -m "Adding final release $full_version via concourse"
popd

echo "Final release $full_version tagged via concourse" > version-tag/annotate-msg
