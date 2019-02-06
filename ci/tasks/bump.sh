#!/usr/bin/env bash

set -euxo pipefail

: "${RUBY_VERSION:?}"
: "${RUBYGEMS_VERSION:?}"
: "${LIBYAML_VERSION:?}"

function replace_if_necessary() {
  package_name=$1
  blobname=$2
  if ! bosh blobs | grep -q "${blobname}"; then
    existing_blob=$(bosh blobs | awk '{print ${package_name}}' | grep "${package_name}" || true)
    if [ -n "${existing_blob}" ]; then
      bosh remove-blob "${existing_blob}"
    fi
    bosh add-blob --sha2 "../${package_name}/${blobname}" "${blobname}"
    bosh upload-blobs
  else
    echo "Blob $blobname already exists. Nothing to do."
  fi
}

cd bumped-ruby-release
git clone ../ruby-release .

set +x
echo "${PRIVATE_YML}" > config/private.yml
set -x

ruby_blob=$(basename "$(ls ../"ruby-$RUBY_VERSION"/*)")
ruby_version="$(echo "$ruby_blob" | sed s/ruby-// | sed s/.tar.gz// )"
rubygems_blob=$(basename "$(ls ../"rubygems-$RUBYGEMS_VERSION"/*)")
rubygems_version="$(echo "$rubygems_blob" | sed s/rubygems-// | sed s/.tgz// )"
yaml_blob=$(basename "$(ls ../"yaml-$LIBYAML_VERSION"/*)")
yaml_version="$(echo "$yaml_blob" | sed s/yaml-// | sed s/.tar.gz// )"
ruby_packagename=${ruby_blob/.tar.gz/}
test_packagename="ruby-$RUBY_VERSION-test"

echo "-----> $(date): Updating blobs"

replace_if_necessary "ruby-$RUBY_VERSION" "$ruby_blob"
replace_if_necessary "rubygems-$RUBYGEMS_VERSION" "$rubygems_blob"
replace_if_necessary "yaml-$LIBYAML_VERSION" "$yaml_blob"

echo "-----> $(date): Rendering package and job templates"


git rm -r packages/*
git rm -r jobs/*

mkdir -p "packages/$ruby_packagename"
mkdir -p "packages/$test_packagename"
mkdir -p "jobs/$test_packagename/templates"

declare -a template_variables=(
  "ruby_blob=$ruby_blob"
  "ruby_version=$ruby_version"
  "rubygems_blob=$rubygems_blob"
  "rubygems_version=$rubygems_version"
  "yaml_blob=$yaml_blob"
  "yaml_version=$yaml_version"
  "test_packagename=$test_packagename"
  "ruby_packagename=$ruby_packagename"
  "test_jobname=$test_packagename"
)

erb "${template_variables[@]}" "ci/templates/packages/ruby/spec.erb" > "packages/$ruby_packagename/spec"
erb "${template_variables[@]}" "ci/templates/packages/ruby/packaging.erb" > "packages/$ruby_packagename/packaging"

erb "${template_variables[@]}" "ci/templates/packages/ruby-test/spec.erb" > "packages/$test_packagename/spec"
erb "${template_variables[@]}" "ci/templates/packages/ruby-test/packaging.erb" > "packages/$test_packagename/packaging"

erb "${template_variables[@]}" "ci/templates/src/compile.env.erb" > "src/compile.env"
erb "${template_variables[@]}" "ci/templates/src/runtime.env.erb" > "src/runtime.env"

erb "${template_variables[@]}" "ci/templates/jobs/ruby-test/monit.erb" > "jobs/$test_packagename/monit"
erb "${template_variables[@]}" "ci/templates/jobs/ruby-test/spec.erb" > "jobs/$test_packagename/spec"
erb "${template_variables[@]}" "ci/templates/jobs/ruby-test/templates/cpi.erb" > "jobs/$test_packagename/templates/cpi"
erb "${template_variables[@]}" "ci/templates/jobs/ruby-test/templates/run.erb" > "jobs/$test_packagename/templates/run"

erb "${template_variables[@]}" "ci/templates/README.md.erb" > README.md

echo "-----> $(date): Creating git commit"

git config user.name "CI Bot"
git config user.email "cf-bosh-eng@pivotal.io"
git add .

git --no-pager diff --cached

if [[ "$( git status --porcelain )" != "" ]]; then
  git commit -am "Bump packages"
fi
