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
packagename=${ruby_blob/.tar.gz/}

git rm -r packages/*
mkdir -p "packages/$packagename"
cat "ci/package_templates/ruby/spec" | sed "s/<RUBY_BLOB>/$ruby_blob/" | sed "s/<RUBYGEMS_BLOB>/$rubygems_blob/" | sed "s/<YAML_BLOB>/$yaml_blob/"| sed "s/<PACKAGENAME>/$packagename/" > "packages/$packagename/spec"
cat "ci/package_templates/ruby/packaging" | sed "s/<RUBY_VERSION>/$ruby_version/" | sed "s/<RUBYGEMS_VERSION>/$rubygems_version/" | sed "s/<YAML_VERSION>/$yaml_version/" > "packages/$packagename/packaging"

testpackagename="ruby-$RUBY_VERSION-test"
mkdir -p "packages/$testpackagename"
cat "ci/package_templates/ruby-test/spec" | sed "s/<RUBY_PACKAGENAME>/$packagename/"| sed "s/<PACKAGENAME>/$testpackagename/" > "packages/$testpackagename/spec"
cat "ci/package_templates/ruby-test/packaging" | sed "s/<RUBY_PACKAGENAME>/$packagename/" > "packages/$testpackagename/packaging"

cat "ci/package_templates/compile.env" | sed "s/<PACKAGENAME>/$packagename/" > "src/compile.env"
cat "ci/package_templates/runtime.env" | sed "s/<PACKAGENAME>/$packagename/" > "src/runtime.env"

find packages
git add packages

git --no-pager diff --cached

if [[ "$( git status --porcelain )" != "" ]]; then
  git commit -am "Bump packages"
fi
