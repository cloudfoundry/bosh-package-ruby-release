## Ruby Release

To vendor ruby package into your release, run:

```
$ git clone https://github.com/bosh-packages/ruby-release
$ cd ~/workspace/your-release
$ bosh vendor-package <RUBY-PACKAGE-VERSION> ~/workspace/ruby-release
```

Where RUBY-PACKAGE-VERSION is one of the provided ruby 2.5 or 2.6 package names
(e.g. `ruby-2.6.5-r0.29.0` or `ruby-2.5.7-r0.25.0`).
The above code will add a ruby package to `your-release` and introduce a `spec.lock`.

Included packages:

- ruby package with the following blobs:
  - ruby (2.5, or 2.6)
  - rubygems (2.7, or 3.1)
  - yaml (0.1)

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

See [packages/ruby-2.5-test](packages/ruby-2.5-test) and [jobs/ruby-2.5-test](jobs/ruby-2.5-test) for a ruby 2.5 example.

See [packages/ruby-2.6-test](packages/ruby-2.6-test) and [jobs/ruby-2.6-test](jobs/ruby-2.6-test) for a ruby 2.6 example.
