#!/usr/bin/env bash
set -euo pipefail

export PATH="/var/vcap/packages/${PACKAGE}/bin:${PATH}"

git clone input-repo output-repo

pushd "output-repo" >/dev/null
  for dir in $GEM_DIRS; do
    pushd "$dir" >/dev/null

    if [ "$UPDATE_BUNDLER_VERSION" == "true" ]; then
      gem update bundler
    fi

    bundle update

    if [ "$VENDOR" == "true" ]; then
      BUNDLE_GEMFILE="Gemfile" \
      BUNDLE_CACHE_PATH="$VENDOR_PATH" \
      BUNDLE_WITHOUT="development:test" \
      bundle cache \
        --all-platforms \
        --no-install
    fi

    if [ "$(git status --porcelain)" != "" ]; then
      git status
      git add -A
      git config user.email "${GIT_USER_EMAIL}"
      git config user.name "${GIT_USER_NAME}"
      git commit -am "Bump gems"
    else
      echo "No new gem versions"
    fi

    popd >/dev/null
  done
popd >/dev/null
