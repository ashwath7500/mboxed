#!/bin/bash

#
# TODO: Documentation
#

# Minikube default parameters
MINIKUBE_DRIVER='docker'
MINIKUBE_CPUS='8'
MINIKUBE_MEM='4096'

# Run minikube with the required options
minikube start --driver=$MINIKUBE_DRIVER --cpus $MINIKUBE_CPUS --memory $MINIKUBE_MEM --mount --mount-string=$HOME/mnt:/mnt

## Clone the repository with the YAML descriptors for the services
#git clone https://github.com/cernbox/kuboxed.git

# Assign labels to minikube node
kubectl label node minikube nodeApp1=ldap
kubectl label node minikube nodeApp2=eos-mgm
kubectl label node minikube nodeApp3=eos-fstN
kubectl label node minikube nodeApp4=cernbox
kubectl label node minikube nodeApp5=cernbox
kubectl label node minikube nodeApp6=cernboxgateway
kubectl label node minikube nodeApp7=swan 
kubectl label node minikube nodeApp8=swan-users

#Creation of persistant volumes
mkdir -p $HOME/mnt/ldap/userdb
mkdir -p $HOME/mnt/ldap/config
mkdir -p $HOME/mnt/cbox_shares_db/cbox_data
mkdir -p $HOME/mnt/cbox_shares_db/cbox_MySQL

#Deployement of Services
kubectl apply -f BOXED.yaml
kubectl apply -f LDAP.yaml
