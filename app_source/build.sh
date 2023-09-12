#!/usr/bin/env bash
use_stdin=false
use_push=false
list_file="/etc/registry_list"
git --git-dir $(pwd)/.git --work-tree $(pwd) describe --always --tags > __version__

podman_build() {
  echo "Build with TAG: $2"
  podman build -t $1/apiserver:$2 . || exit 2
  if [ $use_push = "true" ]; then
    echo "Push with TAG: $2"
    podman push $1/apiserver:$2 || exit 2
  fi
}

run_build() {
  if [ -f "__version__" ]; then
    podman_build $1 $(cat __version__)
  fi
  podman_build $1 latest
}

for arg in $*; do
  if [ $arg == "--from-stdin" ]; then
    use_stdin=true
  fi
  if [ $arg == "--push" ]; then
    use_push=true
  fi
done
if [ $use_stdin == "true" ]; then
  while read a; do
    run_build $a
  done
elif [ -f $list_file ]; then
  list=$(cat $list_file)
  for l in $list; do
    run_build $l
  done
elif [ $# -gt 0 ]; then
  for a in ${@:1}; do
    run_build $a
  done
else
  echo "No registry list is specified"
  echo "Use '--from-stdin' option, list from file '$list_file' or command arguments"
  exit 1
fi
