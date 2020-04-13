#!/bin/bash

# Set the directory to this script's current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

source ./settings.sh

#docker rmi ${IMAGE_NAME}
docker build --force-rm \
	--rm \
	--build-arg FQDN=${FQDN} \
	--build-arg BASE_URL=${BASE_URL} \
	--tag ${IMAGE_NAME} .

