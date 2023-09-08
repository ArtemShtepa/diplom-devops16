#!/usr/bin/env bash
use_stdin=false
list_file="/etc/registry_list"

build() {
  if [ -f "__version__" ]; then
    podman build -t $1/apiserver:$(cat __version__) . || exit 2
    podman push $1/apiserver:$(cat __version__) || exit 2
  fi
  podman build -t $1/apiserver:latest . || exit 2
  podman push $1/apiserver:latest || exit 2
}

for arg in $*; do
  if [ $arg == "--from-stdin" ]; then
    use_stdin=true
  fi
done
if [ $use_stdin == "true" ]; then
  while read a; do
    build $a
  done
elif [ -f $list_file ]; then
  list=$(cat $list_file)
  for l in $list; do
    build $l
  done
elif [ $# -gt 0 ]; then
  for a in ${@:1}; do
    build $a
  done
else
  echo "No registry list is specified"
  echo "Use '--from-stdin' option, list from file '$list_file' or command arguments"
  exit 1
fi
