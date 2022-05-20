#! /usr/bin/sh

CONTAINER_IMAGE_NAME=${1:"hugo-server:latest"}
GIT_REMOTE_ORIGIN='origin'
GIT_REMOTE_BRANCH='master'

[ ! -f ./Makefile ] && \
    echo "could'nt find Makefile, please run the script from project root" && exit 1

command -v docker 
[[ ! $? -eq 0 ]] && \ # get the exist code of the "command" command and check if it failed
    echo "docker is not installed or not in path, this script uses docker for deployment" && exit 1


git pull --depth 1 $GIT_REMOTE_ORIGIN $GIT_REMOTE_BRANCH
make build  # build the project static files
docker build --compress --rm -t $CONTAINER_IMAGE_NAME . 
docker run -it $CONTAINER_IMAGE_NAME
