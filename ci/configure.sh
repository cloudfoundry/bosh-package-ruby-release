#!/usr/bin/env bash

if [[ $(lpass status -q; echo $?) != 0 ]]; then
  echo "Login with lpass first"
  exit 1
fi

dir=$(dirname $0)

fly -t ${CONCOURSE_TARGET:-director} \
  sp -p ruby-release \
  -c $dir/pipeline.yml \
  -l <(lpass show --notes 'ruby-release pipeline vars')
