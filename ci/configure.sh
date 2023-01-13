#!/usr/bin/env bash

pipeline_config=$(mktemp)
ytt -f "$(dirname $0)" > $pipeline_config

fly -t ${CONCOURSE_TARGET:-bosh-ecosystem} \
  sp -p ruby-release \
  -c $pipeline_config
