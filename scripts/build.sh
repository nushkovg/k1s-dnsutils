#!/bin/bash

# Enable buildx features for cross-architecture builds
export DOCKER_CLI_EXPERIMENTAL=enabled

# Build the image
docker buildx build --platform linux/arm/v7 --tag $IMAGE .
