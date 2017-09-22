#!/bin/bash

set -e # -x

pushd ../
  echo "-----> `date`: Deleting state file and release"
  rm -f manifests/create-env-manifest-state.json manifests/release.tgz

  echo "-----> `date`: Building dev release for create-env"
  bosh create-release --name ruby-release --tarball manifests/release.tgz --force

  pushd manifests
    set +e
    echo "-----> `date`: Creating dummy environment"
    result="$( bosh create-env ./create-env-manifest.yml 2>&1 )"
    set -e

    if [[ "$result" != *"Unexpected external CPI command result: '<nil>'"* ]]; then
      echo -e "$result"
      exit 1
    fi
  popd
popd

echo "-----> `date`: Upload stemcell"
bosh -n upload-stemcell "https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent?v=3445.2" \
  --sha1 7ff35e03ab697998ded7a1698fe6197c1a5b2258 \
  --name bosh-warden-boshlite-ubuntu-trusty-go_agent \
  --version 3445.2

echo "-----> `date`: Delete previous deployment"
bosh -n -d test delete-deployment --force
rm -f creds.yml

echo "-----> `date`: Deploy"
( set -e; cd ./..; bosh -n -d test deploy ./manifests/test.yml )

echo "-----> `date`: Run test errand"
bosh -n -d test run-errand ruby-2.4-test

echo "-----> `date`: Delete deployments"
bosh -n -d test delete-deployment

echo "-----> `date`: Done"
