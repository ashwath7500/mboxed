#!/bin/bash

#
# Shared variables and functions
#



# ----- Variables ----- #
# Minikube default parameters
MINIKUBE_DRIVER='docker'
MINIKUBE_CPUS='8'
MINIKUBE_MEM='4096'

# Docker version
DOCKER_VERSION='19.03.9-3'
CONTAINERD_VERSION='1.2.6-3.3'

# ----- Functions ----- #

# Check to be root
need_root ()
{
  if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
  fi
}

