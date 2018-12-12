#!/usr/bin/env bash

set -eux

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
release_dir="${script_dir}/../.."
build_dir="${script_dir}/../../.."
stemcell="${build_dir}/stemcell/stemcell.tgz"

echo "-----> $(date): Starting BOSH"
"${build_dir}/bosh-src/ci/docker/main-bosh-docker/start-bosh.sh"

source /tmp/local-bosh/director/env

echo "-----> $(date): Creating a new release"
bosh create-release \
  --name ruby-release \
  --tarball "${build_dir}/ruby-release.tgz" \
  --dir "${release_dir}" \
  --force

echo "-----> $(date): Uploading release to director"
bosh upload-release "${build_dir}/ruby-release.tgz"

echo "-----> $(date): Uploading stemcell"
bosh -n upload-stemcell "${stemcell}"

echo "-----> $(date): Deploy test deployment"
bosh -n -d test deploy "${release_dir}/manifests/test.yml"

echo "-----> $(date): Run test errand"
bosh -n -d test run-errand ruby-2.4-test

echo "-----> $(date): Done"
