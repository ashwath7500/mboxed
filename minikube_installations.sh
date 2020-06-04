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
apt-get install -y \
  curl \
  git

# Install dependencies
echo "Installing dependencies..."
apt-get install -y \
  conntrack

# Install minikube
#   Docs at https://kubernetes.io/docs/tasks/tools/install-minikube/
echo "Installing minikube..."
mkdir -p /usr/local/bin/
curl -L https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o /usr/local/bin/minikube
chmod +x /usr/local/bin/minikube
minikube version

# Install kubectl
#   Docs at https://kubernetes.io/docs/tasks/tools/install-kubectl/
echo "Installing kubectl..."
mkdir -p /usr/local/bin/
curl -L https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl
kubectl version

# Install docker
#   Docs at https://docs.docker.com/engine/install/ubuntu/
# TODO: We should consider the ubuntu version
# TODO: Make docker version configurable
echo "Installing docker..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io

# Start docker
echo "Starting docker daemon..."
systemctl status docker > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
  systemctl start docker
fi
docker --version
