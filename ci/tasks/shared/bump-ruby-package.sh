#!/usr/bin/env bash

set -eu

task_dir=$PWD

cd bosh-release

git config --global user.name ${GIT_USER_NAME}
git config --global user.email ${GIT_USER_EMAIL}

echo "${PRIVATE_YML}" > config/private.yml

prefix_arg=""
if [ -n "${PACKAGE_PREFIX}" ]; then
  prefix_arg="--prefix=${PACKAGE_PREFIX}"
fi

bosh vendor-package ${prefix_arg} ${PACKAGE} "$task_dir/ruby-release"

package_version=$(cat "$task_dir/ruby-release/packages/${PACKAGE}/version")

if [ -n "${RUBY_VERSION_PATH:=}" ]; then
  echo "${package_version}" > "${RUBY_VERSION_PATH}"
fi

if [ -z "$(git status --porcelain)" ]; then
  exit
fi

git add -A

git commit -m "Update ${PACKAGE} package to ${package_version} from ruby-release"
