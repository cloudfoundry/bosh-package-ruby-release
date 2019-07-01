#!/usr/bin/env bash

set -euxo pipefail

: "${RUBY_VERSION:?}"
: "${RUBYGEMS_VERSION:?}"
: "${LIBYAML_VERSION:?}"

function replace_if_necessary() {
  package_name=$1
  blobname=$2
  blob_location=${3:-"../${package_name}"}
  set +x
  bosh_blobs=$(bosh blobs 2>&1)
  set -x
  if ! echo $bosh_blobs | grep -q "$blobname"; then
    echo "Adding new blob ${blobname}"
    bosh add-blob --sha2 "${blob_location}/${blobname}" "${blobname}"
    bosh upload-blobs
  else
    echo "Blob $blobname already exists"
  fi
}

cd bumped-ruby-release
git clone ../ruby-release .

set +x
echo "${PRIVATE_YML}" > config/private.yml
set -x

bosh_release_version=$( cat ../semver/version )
ruby_blob=$(basename "$(ls ../"ruby"/*)")
ruby_version="$(cat ../"ruby"/.resource/version)"
rubygems_blob=$(basename "$(ls ../"rubygems"/*)")
rubygems_version="$(cat ../"rubygems"/.resource/version)"
yaml_blob=$(basename "$(ls ../"yaml-$LIBYAML_VERSION"/*)")
yaml_version="$(cat ../"yaml-$LIBYAML_VERSION"/.resource/version)"
ruby_packagename=${ruby_blob/.tar.gz/}-r${bosh_release_version}
test_packagename="ruby-$RUBY_VERSION-test"

echo "-----> $(date): Updating blobs"

bosh blobs
replace_if_necessary "ruby-$RUBY_VERSION" "$ruby_blob" "../ruby"
replace_if_necessary "rubygems-$RUBYGEMS_VERSION" "$rubygems_blob" "../rubygems"
replace_if_necessary "yaml-$LIBYAML_VERSION" "$yaml_blob"

echo "-----> $(date): Rendering package and job templates"


git rm -r packages/ruby-${RUBY_VERSION}* && :
git rm -r jobs/ruby-${RUBY_VERSION}* && :

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

erb "${template_variables[@]}" "ci/templates/src/compile.env.erb" > "src/compile-$ruby_version.env"
erb "${template_variables[@]}" "ci/templates/src/runtime.env.erb" > "src/runtime-$ruby_version.env"

erb "${template_variables[@]}" "ci/templates/jobs/ruby-test/monit.erb" > "jobs/$test_packagename/monit"
erb "${template_variables[@]}" "ci/templates/jobs/ruby-test/spec.erb" > "jobs/$test_packagename/spec"
erb "${template_variables[@]}" "ci/templates/jobs/ruby-test/templates/cpi.erb" > "jobs/$test_packagename/templates/cpi"
erb "${template_variables[@]}" "ci/templates/jobs/ruby-test/templates/run.erb" > "jobs/$test_packagename/templates/run"

for blob in $(bosh blobs | awk '{print $1}')
do
  if ! grep -q -R $blob packages; then
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
