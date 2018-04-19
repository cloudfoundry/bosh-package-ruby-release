#!/bin/bash

set -e

absolute_path() {
  (cd "$1" && pwd)
}

scripts_path=$(absolute_path "$(dirname "$0")" )
release_dir="${scripts_path}/.."

echo "-----> $(date): Deleting state file and release"
rm -f "${release_dir}/manifests/create-env-manifest-state.json" "${release_dir}/manifests/release.tgz"

echo "-----> $(date): Building dev release for create-env"
bosh create-release \
  --name ruby-release \
  --tarball "${release_dir}/manifests/release.tgz" \
  --dir "${release_dir}" \
  --force

set +e
echo "-----> $(date): Creating dummy environment"
result="$( bosh create-env "${release_dir}/manifests/create-env-manifest.yml" --state "${release_dir}/manifests/create-env-manifest-state.json" 2>&1 )"
set -e

if [[ "$result" != *"Unexpected external CPI command result: '<nil>'"* ]]; then
  echo -e "$result"
  exit 1
fi

echo "-----> $(date): Creating and Uploading the Release"
bosh create-release --dir "${release_dir}" --force

bosh upload-release  --dir "${release_dir}" --rebase

echo "-----> $(date): Upload stemcell"
bosh -n upload-stemcell "https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent?v=3541.12" \
  --sha1 14bd6dd50d3caa913af97846eab39e5075b240d7 \
  --name bosh-warden-boshlite-ubuntu-trusty-go_agent \
  --version 3541.12

echo "-----> $(date): Update Cloud Config"
bosh -n update-cloud-config "${release_dir}/manifests/cloud-config.yml"

echo "-----> $(date): Delete previous deployment"
bosh -n -d test delete-deployment --force

echo "-----> $(date): Deploy"
bosh -n -d test deploy "${release_dir}/manifests/test.yml"

echo "-----> $(date): Run test errand"
bosh -n -d test run-errand ruby-2.4-test

echo "-----> $(date): Delete deployments"
bosh -n -d test delete-deployment

echo "-----> $(date): Done"
