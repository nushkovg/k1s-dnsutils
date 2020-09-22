############################
### Build dnsutils image ###
############################
FROM ubuntu:bionic

LABEL maintainer="github.com/nushkovg"

# Install required packages
RUN apt-get update \
    && apt-get install -yq dnsutils \
    && apt-get install -yq curl \
    && apt-get install -yq libxml2-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists
