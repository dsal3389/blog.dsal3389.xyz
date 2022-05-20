#! /usr/bin/sh

# this script pull the latest image from the git repo, build the hugo files,
# and deploy it to a single docker container, this is for production testing, it is recommended
# to deploy it with k8s or docker swarm

# it also uses volume to share the build files with the container,
# if the container does not exists it create new image and run new container from that image


CONTAINER_IMAGE_NAME=${1:-"hugo-server:latest"}

CONTAINER_HOST_MOUNT_DIR="$(pwd)/public"
CONTAINER_MOUNT_DIR="/usr/share/nginx/html"

CONTAINER_EXTERNAL_PORT=3001
CONTAINER_INTERNAL_PORT=80

GIT_REMOTE_ORIGIN='origin'
GIT_REMOTE_BRANCH='main'


[[ $(id --user) -eq 0 ]] && \
    CMD_PREFIX="" || CMD_PREFIX="sudo"

[ ! -f ./Makefile ] && \
    printf "[$0]: could'nt find Makefile, please run the script from project root\n" > /dev/stderr \
         && exit 1


printf "[$0]: pulling git from ${GIT_REMOTE_ORIGIN} -> ${GIT_REMOTE_BRANCH}\n"
git pull --depth 1 $GIT_REMOTE_ORIGIN $GIT_REMOTE_BRANCH 1> /dev/null

make build &> /dev/null
[ ! $? -eq 0 ] && \
    printf "[$0]: failed building hugo ($?), please run make build and check fix the error\n" > /dev/stderr && exit 1

RUNNING_CONTAINER_ID=$($CMD_PREFIX docker ps -q --filter "ancestor=$CONTAINER_IMAGE_NAME")

[ -z $RUNNING_CONTAINER_ID ] &&  # if there is no ID, create the image from the repo docker file and create a container from it
    printf "[$0]: couldn't find running container creating new docker image and a runnnig container: ${CONTAINER_IMAGE_NAME}\n" && \
        $CMD_PREFIX docker build --compress --rm -t $CONTAINER_IMAGE_NAME ./ && \
        RUNNING_CONTAINER_ID=$(
            $CMD_PREFIX docker run \
                -d \
                -p$CONTAINER_EXTERNAL_PORT:$CONTAINER_INTERNAL_PORT \
                --volume $CONTAINER_HOST_MOUNT_DIR:$CONTAINER_MOUNT_DIR:ro \
                $CONTAINER_IMAGE_NAME
            )

printf "[$0]: running container (id: $RUNNING_CONTAINER_ID)\n"
printf "[$0]: moving build files to host mount dir $CONTAINER_HOST_MOUNT_DIR\n"
mv ./public/* $CONTAINER_HOST_MOUNT_DIR &> /dev/null
exit 0