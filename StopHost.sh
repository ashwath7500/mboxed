#!/bin/bash
# Import variables and functions
source etc/common.sh



# Preliminary Checks
echo ""
echo "Preliminary checks..."
need_root

# Removing all resources
sudo kubectl delete all --all -n boxed
sudo kubectl delete namespaces boxed
NODE_NAME=$(sudo kubectl get nodes | grep master | cut -d ' ' -f 1)
sudo kubectl label node $NODE_NAME nodeApp-
#Removing yaml files
sudo rm -R ./kuboxed
sudo rm ./eos-storage-fst1.yaml
sudo rm ./eos-storage-fst2.yaml
sudo rm ./eos-storage-fst3.yaml
