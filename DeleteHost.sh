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

#Deleting all images
imgs=$(grep 'image:' ./kuboxed/SWAN.yaml | sed  's/image://')
docker rmi $imgs
imgs=$(grep 'image:' ./kuboxed/LDAP.yaml | sed  's/image://')
docker rmi $imgs
imgs=$(grep 'image:' ./kuboxed/eos-storage-mgm.yaml | sed  's/image://')
docker rmi $imgs
imgs=$(grep 'image:' ./kuboxed/eos-storage-fst.template.yaml | sed  's/image://')
docker rmi $imgs
imgs=$(grep 'image:' ./kuboxed/CERNBOX.yaml | sed  's/image://')
docker rmi $imgs
#Removing yaml files
sudo rm -R ./kuboxed
