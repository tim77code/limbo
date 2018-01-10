#!/bin/bash -ve

## The acrobatics here (ie, output to limbo-tmp, using sed to extract
## password) are work-arounds to both awscli and MacOS problems.

docker-compose.exe -f cmds.windows.yml run aws ecr get-login \
                    --region us-east-1 --no-include-email > limbo-tmp

cat limbo-tmp | sed 's/docker login -u AWS -p \([^ ]*\) .*/\1/' \
 | docker.exe login -u AWS --password-stdin \
              560921689673.dkr.ecr.us-east-1.amazonaws.com

rm limbo-tmp

docker.exe tag tim77/limbo:latest $IMAGE_THIS_BUILD
docker.exe push $IMAGE_THIS_BUILD
