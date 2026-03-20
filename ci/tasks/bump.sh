#!/usr/bin/env bash

set -euxo pipefail

: "${RUBY_VERSION:?}"
: "${RUBYGEMS_VERSION:?}"
: "${LIBYAML_VERSION:?}"

function replace_if_necessary() {
  package_name=$1
  blob_name=$2
  blob_location=${3:-"../${package_name}"}
  set +x
  bosh_blobs=$(bosh blobs 2>&1)
  set -x
  if ! echo "${bosh_blobs}" | grep -q "${blob_name}"; then
    echo "Adding new blob ${blob_name}"
    bosh add-blob --sha2 "${blob_location}/${blob_name}" "${blob_name}"
    bosh upload-blobs
  else
    echo "Blob ${blob_name} already exists"
  fi
}

cd ruby-release

set +x
echo "${PRIVATE_YML}" > config/private.yml
set -x

ruby_blob=$(basename "$(ls ../ruby/*)")
ruby_patch_version="$(cat ../ruby/.resource/version)"
rubygems_blob=$(basename "$(ls ../rubygems/*)")
rubygems_version="$(cat ../rubygems/.resource/version)"
yaml_blob=$(basename "$(ls ../libyaml/*)")
yaml_version="$(cat ../libyaml/.resource/version)"
ruby_package_name="ruby-${RUBY_VERSION}"
test_package_name="ruby-${RUBY_VERSION}-test"

if [ "${LIBYAML_VERSION}" != "0.1" ]; then
  if [ ! -e "./src/patches/libyaml-${yaml_version}.patch" ]; then
    echo "src/patches/libyaml-${yaml_version}.patch not found! Create patch to revert ... behavior."
    exit 1
  fi
fi

echo "-----> $(date): Updating blobs"

bosh blobs
replace_if_necessary "ruby-${RUBY_VERSION}" "${ruby_blob}" "../ruby"
replace_if_necessary "rubygems-${RUBYGEMS_VERSION}" "${rubygems_blob}" "../rubygems"
replace_if_necessary "yaml-${LIBYAML_VERSION}" "${yaml_blob}" "../libyaml"

echo "-----> $(date): Rendering package and job templates"


git rm -r packages/ruby-"${RUBY_VERSION}"* && :
git rm -r jobs/ruby-"${RUBY_VERSION}"* && :

mkdir -p "packages/${ruby_package_name}"
mkdir -p "packages/${test_package_name}"
mkdir -p "jobs/${test_package_name}/templates"

declare -a template_variables=(
  "ruby_blob=${ruby_blob}"
  "ruby_version=${RUBY_VERSION}"
  "ruby_patch_version=${ruby_patch_version}"
  "rubygems_blob=${rubygems_blob}"
  "rubygems_version=${rubygems_version}"
  "yaml_blob=${yaml_blob}"
  "yaml_version=${yaml_version}"
  "test_package_name=${test_package_name}"
  "ruby_package_name=${ruby_package_name}"
  "test_jobname=${test_package_name}"
)

erb "${template_variables[@]}" "ci/templates/packages/ruby/spec.erb" > "packages/${ruby_package_name}/spec"
erb "${template_variables[@]}" "ci/templates/packages/ruby/packaging.erb" > "packages/${ruby_package_name}/packaging"
cp "../ruby/.resource/version" "./packages/${ruby_package_name}/"

erb "${template_variables[@]}" "ci/templates/packages/ruby-test/spec.erb" > "packages/${test_package_name}/spec"
erb "${template_variables[@]}" "ci/templates/packages/ruby-test/packaging.erb" > "packages/${test_package_name}/packaging"

erb "${template_variables[@]}" "ci/templates/src/compile.env.erb" > "src/compile-${RUBY_VERSION}.env"
erb "${template_variables[@]}" "ci/templates/src/runtime.env.erb" > "src/runtime-${RUBY_VERSION}.env"

erb "${template_variables[@]}" "ci/templates/jobs/ruby-test/monit.erb" > "jobs/${test_package_name}/monit"
erb "${template_variables[@]}" "ci/templates/jobs/ruby-test/spec.erb" > "jobs/${test_package_name}/spec"
erb "${template_variables[@]}" "ci/templates/jobs/ruby-test/templates/run.erb" > "jobs/${test_package_name}/templates/run"

for blob in $(bosh blobs | awk '{print $1}')
do
  if ! grep -q -R ${blob} packages; then
    echo "Removing unused blob ${blob}"
    bosh remove-blob "${blob}"
  fi
done

echo "-----> $(date): Creating git commit"

git config user.name "CI Bot"
git config user.email "cf-bosh-eng@pivotal.io"
git add .

git --no-pager diff --cached

if [[ "$( git status --porcelain )" != "" ]]; then
  git commit -am "Bump packages"
fi
