#!/usr/bin/env bash
use_stdin=false
use_build_art=false
use_build_full=false
use_push=false
list_file="/etc/registry_list"

run_podman() {
  if [ "$use_build_art" = true ]; then
    echo "Build with TAG: $2"
    podman build -t $1/apiserver:$2 -f Dockerfile-art . || exit 2
  fi
  if [ "$use_build_full" = true ]; then
    echo "Build with TAG: $2"
    podman build -t $1/apiserver:$2 -f Dockerfile-full . || exit 2
  fi
  if [ "$use_push" = true ]; then
    echo "Push with TAG: $2"
    podman push $1/apiserver:$2 || exit 2
  fi
}

run_registry() {
  if [ -f "__version__" ]; then
    run_podman $1 $(cat __version__)
  fi
  run_podman $1 latest
}

for arg in $*; do
  if [ "$arg" = "--from-stdin" ]; then
    use_stdin=true
  fi
  if [ "$arg" = "--build-art" ]; then
    use_build_art=true
  fi
  if [ "$arg" = "--build-full" ]; then
    use_build_full=true
  fi
  if [ "$arg" = "--push" ]; then
    use_push=true
  fi
done
if [[ $use_build_art = "false" && $use_build_full = "false" && $use_push = "false" ]]; then
  echo "No operation specified"
  echo "Use key --build-art to build image from CI artifacts"
  echo "Use key --build-bull to compile application and build image"
  echo "Use key --push to push image to registry"
  exit 3
elif [ "$use_stdin" = true ]; then
  while read a; do
    run_registry $a
  done
elif [ -f "$list_file" ]; then
  list=$(cat $list_file)
  for l in $list; do
    run_registry $l
  done
elif [ $# -gt 0 ]; then
  for a in ${@:1}; do
    run_registry $a
  done
else
  echo "No registry list is specified"
  echo "Use '--from-stdin' option, list from file '$list_file' or command arguments"
  exit 1
fi