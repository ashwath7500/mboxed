#!/bin/bash

#
# TODO: Instructions here
#

#TODO: We should bail out and ask the user if some of the software is already installed


# Import variables and functions
source etc/common.sh


# Check to be root
need_root

#Detect the os
detect_os

# Install basic software
echo "Installing basic software..."
apt-get install -y \
  curl \
  git

# Install dependencies
echo "Installing dependencies..."
apt-get install -y \
  conntrack

# Install minikube
#   Docs at https://kubernetes.io/docs/tasks/tools/install-minikube/
#echo "Installing minikube..."
install_minikube
# Install kubectl
#   Docs at https://kubernetes.io/dcs/tasks/tools/install-kubectl/
echo "Installing kubectl..."
check_kube_version
install_kubernetes

# Install docker
#   Docs at https://docs.docker.com/engine/install/ubuntu/
# TODO: We should consider the ubuntu version
# TODO: Make docker version configurable
echo "Installing docker..."
check_docker_version
install_docker

# Start docker
echo "Starting docker daemon..."
systemctl status docker > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
  systemctl start docker
fi
docker --version
