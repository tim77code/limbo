#!/bin/bash -ve

# Designed to be used from one's laptop and from Travis.  The
# existence of TRAVIS_BRANCH is used to test where it's running.
#
# In both cases, the standard AWS_ environment variables need to be
# defined to provide the AWS credentials for accessing ECR and ECS.
# Also, SERVICE_NAME must be defined, which determines both the name of the
# image in the Docker registry and the name of the service in ECS.
#
# When running on a laptop, `git symbolic-ref --short HEAD` is used in
# place of TRAVIS_BRANCH to determine what branch is being built (so
# it must be run from inside the repo).  Further, MASTER_SLACK_TOKEN
# or WIP_SLACK_TOKEN must be defined (based on whether this is master
# or WIP deploy).

if [ $# -ne 1 ]; then
  echo "Usage: $0 start|stop|update"
  exit 1
fi

if [ "$TRAVIS_BRANCH" != "" ]; then
  if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    echo Skipping travis_deploy for pull request
    exit 0
  fi
  export THE_BRANCH=$TRAVIS_BRANCH
else
  export THE_BRANCH=`git symbolic-ref --short HEAD`
fi

export TYPE=`expr "$THE_BRANCH" : ".*\(wip$\)"`
if [ "$TYPE" != "wip" ]; then
  export TYPE=`expr "$THE_BRANCH" : ".*\(master$\)"`
  if [ "$TYPE" != "master" ]; then
    echo Branch name does not end in "wip" or "master": skip deploy
    exit 0
  fi
fi

if [ "$SLACK_TOKEN" = "" ]; then
  if [ "$TYPE" = "master" ]; then
    export SLACK_TOKEN=$MASTER_SLACK_TOKEN
  else
    export SLACK_TOKEN=$WIP_SLACK_TOKEN
  fi
fi
if [ "$SLACK_TOKEN" = "" ]; then
  echo Missing ${TYPE}_SLACK_TOKEN
  exit 1
fi

export IMAGE_THIS_BUILD=560921689673.dkr.ecr.us-east-1.amazonaws.com/tim77/$SERVICE_NAME:$TYPE
export LIMBO_CLOUDWATCH="Limbo&Botname=${SERVICE_NAME}&Env=${TYPE}"

case "$1" in
  start)
    bin/ecr_push.sh
    docker-compose.exe --file cmds.yml run \
      ecs-cli compose --file docker-compose.yml --region us-east-1 --cluster limbo \
        --project-name $SERVICE_NAME-$TYPE service up
    ;;

  stop)
    docker-compose.exe --file cmds.yml run \
      ecs-cli compose --file docker-compose.yml --region us-east-1 --cluster limbo \
        --project-name $SERVICE_NAME-$TYPE service rm
    ;;

  update)
    if (docker-compose.exe --file cmds.yml run ecs-cli ps --region us-east-1 --cluster limbo \
         | grep RUNNING | grep $SERVICE_NAME); then
      bin/ecr_push.sh
      docker-compose.exe --file cmds.yml run \
        ecs-cli compose --file docker-compose.yml --region us-east-1 --cluster limbo \
          --project-name $SERVICE_NAME-$TYPE service up
    else
      echo "Service not running, so not pushing an update."
    fi
    ;;

  *)
    echo "Usage: $0 start|update|stop"
    exit 1
esac
