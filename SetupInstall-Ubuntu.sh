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
apt-get install -y install \
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
#   Docs at https://docs.docker.com/engine/install/ubuntu/
# TODO: We should consider the ubuntu version
# TODO: Make docker version configurable
echo "Installing docker..."
dpkg -i \
  https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/docker-ce_19.03.9~3-0~ubuntu-bionic_amd64.deb \
  https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/docker-ce-cli_19.03.9~3-0~ubuntu-bionic_amd64.deb \
  https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/containerd.io_1.2.6-3_amd64.deb

# Start docker
echo "Starting docker daemon..."
systemctl status docker > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
  systemctl start docker
fi
docker --version

