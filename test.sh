#!/bin/bash

# Set the directory to this script's current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

source ./settings.sh

docker run --rm -i -t \
	-e CONTAINER_NAME=${CONTAINER_NAME} \
	-e FQDN=${FQDN} \
	-e BASE_URL=${BASE_URL} \
	-e HTTP_PORT=${HTTP_PORT} \
	-e HTTPS_PORT=${HTTPS_PORT} \
	-e DNS_SERVER=${DNS_SERVER} \
	--memory=${MAX_MEMORY} \
	--memory-swap=${MAX_MEMORY} \
	--name ${CONTAINER_NAME} \
	-p ${HTTP_PORT}:80 \
	-p ${HTTPS_PORT}:443 \
	${IMAGE_NAME} bash

