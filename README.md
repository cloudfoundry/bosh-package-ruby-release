## Ruby Release

To vendor ruby package into your release, run:

```
$ git clone https://github.com/bosh-packages/ruby-release
$ cd ~/workspace/your-release
$ bosh vendor-package ruby-2.4-r5 ~/workspace/ruby-release
```

The above code will add `ruby-2.4-r5` to `your-release` and introduce a `spec.lock`.

Included packages:

- ruby-2.4-r5 which includes:
  - ruby-2.4.5
  - yaml-0.1.7
  - rubygems-2.7.8

Included functions in `compile.env`:

- `bosh_bundle` which runs `bundle install ...` targeted at `${BOSH_INSTALL_TARGET}`
- `bosh_generate_runtime_env` which generates `${BOSH_INSTALL_TARGET}/bosh/runtime.env`

To use `ruby-*` package for compilation in your packaging script:

```bash
#!/bin/bash -eu
source /var/vcap/packages/ruby-2.4-r5/bosh/compile.env
...
bosh_bundle
bosh_generate_runtime_env
```

To use `ruby-*` package at runtime in your job scripts:

```bash
#!/bin/bash -eu
source /var/vcap/packages/ruby-2.4-r5/bosh/runtime.env
source /var/vcap/packages/your-package/bosh/runtime.env
bundle exec ...
```

See [packages/ruby-2.4-test](packages/ruby-2.4-test) and [jobs/ruby-2.4-test](jobs/ruby-2.4-test) for example.

## Development

To run tests `BOSH_ENVIRONMENT=vbox ./tests/run.sh`
