## Ruby Release

To vendor ruby package into your release, run:

```
$ git clone https://github.com/bosh-packages/ruby-release
$ cd ~/workspace/your-release
$ bosh vendor-package <RUBY-PACKAGE-VERSION> ~/workspace/ruby-release
```

Where RUBY-PACKAGE-VERSION is one of the provided ruby package names
The above code will add a ruby package to `your-release` and introduce a `spec.lock`.

A Concourse task can be found in `ci/tasks/shared` to automatically bump the package in your bosh release.

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
