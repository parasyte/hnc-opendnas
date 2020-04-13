#!/bin/bash

# Docker image name
IMAGE_NAME="hnc-opendnas:latest"

# The container's name when spawning
CONTAINER_NAME="hnc-opendnas"

# Maximum memory for this container
MAX_MEMORY="512m"

# FQDN - Domain name
FQDN="opendnas.localhost"

# Base URL
BASE_URL="https://${FQDN}/"

# HTTP port
HTTP_PORT="80"

# HTTPS Port
HTTPS_PORT="443"

# DNS Server for players to connect to
DNS_SERVER="0.0.0.0"

# Enable public metrics
#PUBLIC_METRICS="FALSE"

# Administrator password for accessing site metrics
#ADMIN_PASSWORD=""

