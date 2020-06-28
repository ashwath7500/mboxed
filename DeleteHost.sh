#!/bin/bash
# Import variables and functions
source etc/common.sh



# Preliminary Checks
echo ""
echo "Preliminary checks..."
need_root 

git clone https://github.com/cernbox/kuboxed.git
chmod -R 777 ./kuboxed
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
#Removing the mount path
sudo rm -R /mnt
