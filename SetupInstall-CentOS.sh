#!/bin/bash

#
# TODO: Instructions here
#

#TODO: We should bail out and ask the user if some of the software is already installed

# Import variables and functions
source etc/common.sh


# Check to be root
need_root


# Install basic software
echo "Installing basic software..."
yum -y install \
  curl \
  git


# Install minikube
#   Docs at https://kubernetes.io/docs/tasks/tools/install-minikube/
echo "Installing minikube..."
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
mkdir -p /usr/local/bin/
install minikube /usr/local/bin/
rm -f minikube


# Install docker
#   Docs at https://docs.docker.com/engine/install/centos/
# TODO: We should consider CentOS version (Docker not yet available for C8?)
echo "Installing docker..."
yum -y install \
  https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-"$DOCKER_VERSION".el7.x86_64.rpm \
  https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-cli-"$DOCKER_VERSION".el7.x86_64.rpm \
  https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-"$CONTAINERD_VERSION".el7.x86_64.rpm

# Start docker
echo "Starting docker daemon..."
systemctl status docker > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
  systemctl start docker
fi
docker --version
