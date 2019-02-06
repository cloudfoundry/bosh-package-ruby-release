#!/usr/bin/env bash

set -euxo pipefail

: ${RUBY_VERSION:?}
: ${RUBYGEMS_VERSION:?}
: ${LIBYAML_VERSION:?}

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${BASE_DIR}/bump-helpers.sh"

declare -a versions=(
"ruby-${RUBY_VERSION}"
"rubygems-${RUBYGEMS_VERSION}"
"yaml-${LIBYAML_VERSION}"
)

cd bumped-ruby-release
git clone ../ruby-release .



set +x
echo "${PRIVATE_YML}" > config/private.yml
set -x

set_git_config "CI Bot" "cf-bosh-eng@pivotal.io"

for v in "${versions[@]}"
do
  replace_if_necessary "$v"
done


ruby_blob=$(basename "$(ls ../"ruby-$RUBY_VERSION"/*)")
ruby_version="$(echo "$ruby_blob" | sed s/ruby-// | sed s/.tar.gz// )"
rubygems_blob=$(basename "$(ls ../"rubygems-$RUBYGEMS_VERSION"/*)")
rubygems_version="$(echo "$rubygems_blob" | sed s/rubygems-// | sed s/.tgz// )"
yaml_blob=$(basename "$(ls ../"yaml-$LIBYAML_VERSION"/*)")
yaml_version="$(echo "$yaml_blob" | sed s/yaml-// | sed s/.tar.gz// )"
ruby_packagename=${ruby_blob/.tar.gz/}
test_packagename="ruby-$RUBY_VERSION-test"

git rm -r packages/*
git rm -r jobs/*

mkdir -p "packages/$ruby_packagename"
mkdir -p "packages/$test_packagename"
mkdir -p "jobs/$test_packagename/templates"

declare -a template_variables=(
  ruby_blob=$ruby_blob
  ruby_version=$ruby_version
  rubygems_blob=$rubygems_blob
  rubygems_version=$rubygems_version
  yaml_blob=$yaml_blob
  yaml_version=$yaml_version
  test_packagename=$test_packagename
  ruby_packagename=$ruby_packagename
  test_jobname=$test_packagename
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

git add packages jobs src

git --no-pager diff --cached

if [[ "$( git status --porcelain )" != "" ]]; then
  git commit -am "Bump packages"
fi
