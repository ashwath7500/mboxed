#!/bin/bash
# Import variables and functions
source etc/common.sh



# Preliminary Checks
echo ""
echo "Preliminary checks..."
need_root

# Removing Containers
sudo kubectl delete --all pods -n=boxed
sudo kubectl delete --all svc -n=boxed
sudo kubectl delete --all deployments -n=boxed
