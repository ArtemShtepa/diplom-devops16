#!/usr/bin/env bash
use_stdin=false
use_build_art=false
use_build_full=false
use_push=false
use_deploy=false
use_clean=false
list_file="/etc/registry_list"
deploy_path="$HOME/deploy"

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

run_deploy() {
  if ! [ -d "$deploy_path" ]; then
    echo "No Deploy directory existed"
    exit 4
  fi
  cd $deploy_path
  if [ "$CLUSTER_ENV" = "" ]; then
    echo "No environment set"
    exit 5
  fi;
  if [ "$APP_IMAGE_TAG" = "" ]; then
    echo "No image tag set"
    exit 6
  fi;
  max_retry=5
  counter=0
  export QBEC_YES=true
  until qbec apply $CLUSTER_ENV --wait --vm:ext-str APP_IMAGE_TAG=$APP_IMAGE_TAG
  do
    echo "Wait..."
    sleep 5
    [[ counter -eq $max_retry ]] && echo "Failed!" && exit 7
    ((counter++))
    echo "Trying again #$counter"
  done
  echo "Seccess!"
}

run_clean() {
  if ! [ -d "$deploy_path" ]; then
    echo "No Deploy directory existed"
    exit 4
  fi
  cd $deploy_path
  if [ "$CLUSTER_ENV" = "" ]; then
    echo "No environment set"
    exit 5
  fi;
  export QBEC_YES=true
  qbec delete $CLUSTER_ENV
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
  if [ "$arg" = "--deploy" ]; then
    use_deploy=true
  fi
  if [ "$arg" = "--clean" ]; then
    use_clean=true
  fi
done

if [ "$use_deploy" = "true" ]; then
  run_deploy
elif [ "$use_clean" = "true" ]; then
  run_clean
elif [[ $use_build_art = "false" && $use_build_full = "false" && $use_push = "false" && $use_deploy = "false" ]]; then
  echo "No operation specified"
  echo "Use key --build-art to build image from CI artifacts"
  echo "Use key --build-bull to compile application and build image"
  echo "Use key --push to push image to registry"
  echo "Use key --deploy to deploy app by qbec"
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