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
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client
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
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

# Start docker
echo "Starting docker daemon..."
systemctl status docker > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
  systemctl start docker
fi
docker --version

sudo apt-get install -y conntrack
