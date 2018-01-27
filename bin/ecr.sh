#!/bin/bash

if [ "$TRAVIS_BRANCH" != "" ]; then
  ## Help debug broken builds
  set -v
fi

if [ $# -ne 2 ]; then
  # Force usage to be printed
  CMD="error"
else
  CMD=$1
  REGION=`expr "$2" : "[^.]*.dkr.ecr.\([^.]*\)"`
  if [ $? -ne 0 ]; then
    echo "Badly formatted image name (need <ecr-host>/<repository>[:tag]): $2"
    exit 1
  fi
  REGISTRY=`expr "$2" : "\([^/]*\)"`
  if [ $? -ne 0 ]; then
    echo "Badly formatted image name (need <ecr-host>/<repository>[:tag]): $2"
    exit 1
  fi
  REPO=`expr "$2" : "[^/]*/\([^:]*\)"`
  if [ $? -ne 0 ]; then
    echo "Badly formatted image name (need <ecr-host>/<repository>[:tag]): $2"
    exit 1
  fi
fi

case "$CMD" in
  mkrepo)
    aws ecr describe-repositories --region $REGION --repository-names $REPO >& /dev/null
    if [ $? -ne 0 ]; then
      aws ecr create-repository --region $REGION --repository-names $REPO
    else
      echo "Repository $REPO already exists."
    fi
    ;;
    

  push)
    aws ecr get-login --region $REGION --no-include-email \
     | sed 's/docker login -u AWS -p \([^ ]*\) .*/\1/' \
     | docker login -u AWS --password-stdin $REGISTRY
    if [ $? -ne 0 ]; then
      echo "Can't log into Docker registry."
      exit 1
    fi

    docker tag limbo:latest $2 && docker push $2
    if [ $? -ne 0 ]; then
      echo "Can't push latest image."
      exit 1
    fi
    ;;

  *)
    echo "Usage: ecr.sh { mkrepo | push } image"
    exit 1
esac
