## Ruby Release

### What is this?

This ruby-release is provided for the `bosh vendor-package` command. Using said
command you can now add packages to your bosh-release without having to maintain
them yourself (DRY).

### How do I use it?

```sh
  git clone https://github.com/bosh-packages/ruby-release ~/workspace/ruby-release

  cd ~/workspace/magic-release

  bosh vendor-package ruby-2.4 ~/workspace/ruby-release
```

The above code will add `ruby-2.4` to `magic-release` and introduce a `spec.lock`.
Blobs will also be uploaded for you.

You can now declare packages to depend on `ruby-2.4`; you can use dependency hooks:

... in a `packaging` script
`source /var/vcap/packages/ruby-2.4/bosh/compile.env`

... in a job script/template
`source /var/vcap/packages/ruby-2.4/bosh/runtime.env`

This will put `ruby`, `bundler`, `gem` on the PATH for those consuming scripts.

### Blobs included

- Ruby 2.4 (package `ruby-2.4`)
  - ruby-2.4.2
  - yaml-0.1.7
  - bundler-1.15.3
  - rubygems-2.6.4

### Repository Examples

- (BOSH Director)[https://github.com/cloudfoundry/bosh]
