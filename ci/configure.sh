#!/usr/bin/env bash

if [[ $(lpass status -q; echo $?) != 0 ]]; then
  echo "Login with lpass first"
  exit 1
fi

pipeline_config=$(mktemp)
ytt -f "$(dirname $0)" > $pipeline_config

fly -t ${CONCOURSE_TARGET:-director} \
  sp -p ruby-release \
  -c $pipeline_config \
  -l <(lpass show --notes 'ruby-release pipeline vars')
