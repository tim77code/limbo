#!/bin/bash

# Designed to be used from one's laptop and from Travis.  The
# existence of TRAVIS_BRANCH is used to test where it's running.
#
# In both cases, the standard AWS_ environment variables need to be
# defined to provide the AWS credentials for accessing ECR and ECS.
# Also, $SLACK_TOKEN must be defined.

if [ "$TRAVIS_BRANCH" != "" ]; then
  if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    echo Skipping travis_deploy for pull request
    exit 0
  fi
  ## Help debug broken builds
  set -v
fi

if [ "$SLACK_TOKEN" = "" ]; then
  echo Missing SLACK_TOKEN
  exit 1
fi

if [ "$BOTNAME" = "" ]; then
  export BOTNAME=`limbo --botname || echo ERROR`
  if [ "$BOTNAME" = "ERROR" ]; then
    echo "Can't get botname"
    exit 1
  fi
fi

export IMAGE_THIS_BUILD=560921689673.dkr.ecr.us-east-1.amazonaws.com/tim77/$BOTNAME:latest
export LIMBO_CLOUDWATCH="Limbo&Botname=${BOTNAME}"

case "$1" in
  start)
    ecr.sh push $IMAGE_THIS_BUILD
    ecs-cli compose --file docker-compose.ecs.yml --region us-east-1 --cluster limbo \
      --project-name $BOTNAME service up
    ;;

  stop)
    ecs-cli compose --file docker-compose.ecs.yml --region us-east-1 --cluster limbo \
      --project-name $BOTNAME service rm
    ;;

  update)
    if (ecs-cli ps --region us-east-1 --cluster limbo | grep RUNNING | grep $BOTNAME); then
      ecr.sh push $IMAGE_THIS_BUILD
      ecs-cli compose --file docker-compose.ecs.yml --region us-east-1 --cluster limbo \
        --project-name $BOTNAME service up
    else
      echo "Service not running, so not pushing an update."
    fi
    ;;

  make_ecr_repo)
    ecr.sh mkrepo $IMAGE_THIS_BUILD
    ;;

  ecr_push)
    ecr.sh push $IMAGE_THIS_BUILD
    ;;

  *)
    echo "Usage: $0 start|update|stop|make_ecr_repo|ecr_push"
    exit 1
esac
