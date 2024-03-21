## Ruby Release

To vendor ruby package into your release, run:

```
$ git clone https://github.com/cloudfoundry/bosh-package-ruby-release
$ cd ~/workspace/your-release
$ bosh vendor-package <RUBY-PACKAGE-VERSION> ~/workspace/bosh-package-ruby-release
```

Where RUBY-PACKAGE-VERSION is one of the provided ruby package names
The above code will add a ruby package to `your-release` and introduce a `spec.lock`.

### Shared Concourse tasks

This repository provides a couple helpful Concourse tasks in `ci/tasks/shared` that can help keep the Ruby package vendored in your BOSH release up to date, and bump gem versions.

#### ci/tasks/shared/bump-ruby-package

The `bump-ruby-package` task runs `bosh vendor-package` to automatically update the version of Ruby vendored into your own BOSH release.

* `GIT_USER_EMAIL`: Required. The email that will be used to generate commits.
* `GIT_USER_NAME`: Required. The user name that will be used to generate commits.
* `PACKAGE`: Required. Specifies which package from `ruby-release` that will be vendored into your own BOSH release, e.g. the `ruby-3.2` package.
* `PACKAGE_PREFIX`: Optional. Equivalent to passing `--prefix` to `bosh vendor-package`. For example, specifying a prefix of `myrelease` will vendor in the package as `myrelease-ruby-3.2` instead of just `ruby-3.2`.
* `PRIVATE_YML`: Required. The contents of config/private.yml for your own BOSH release. Necessary to run `bosh vendor-package`.
* `RUBY_VERSION_PATH`: Optional. Relative path within your release to the `.ruby-version` file. When specified, the `.ruby-version` file will be updated with the exact version number (including patch) for the Ruby package.

#### ci/tasks/shared/bump-gems

The `bump-gems` task runs `bundle update` on each of your Gemfiles and optionally vendors them into your repository.

* `GEM_DIRS`: Required. A space-separated list of directories that contain a `Gemfile` to run
* `GIT_USER_EMAIL`: Required. The email that will be used to generate commits.
* `GIT_USER_NAME`: Required. The user name that will be used to generate commits.
* `PACKAGE`: Required. The package you are using in your own BOSH release (e.g. `ruby-3.2`). This ensures that the correct version of bundler will be used to make the updates, preventing issues where the version of bundler in your Gemfile.lock does not get out-of-sync with the version used.
* `VENDOR`: Optional. Boolean value that specifies you want to run `bundle cache` to vendor in the gems into your repository. Defaults to `false`.
* `VENDOR_PATH`: Optional. String value that specifies the BUNDLE_CACHE_PATH environment variable to use when vendoring gems. Default to `vendor/package`.

### Compile and Runtime functions and scripts

Included functions in `compile.env`:

- `bosh_bundle` which runs `bundle install ...` targeted at `${BOSH_INSTALL_TARGET}`
- `bosh_generate_runtime_env` which generates `${BOSH_INSTALL_TARGET}/bosh/runtime.env`

To use `ruby-*` package for compilation in your packaging script:

```bash
#!/bin/bash -eu
source /var/vcap/packages/<RUBY-PACKAGE-VERSION>/bosh/compile.env
...
bosh_bundle
bosh_generate_runtime_env
```

To use `ruby-*` package at runtime in your job scripts:

```bash
#!/bin/bash -eu
source /var/vcap/packages/<RUBY-PACKAGE-VERSION>/bosh/runtime.env
source /var/vcap/packages/your-package/bosh/runtime.env
bundle exec ...
```
