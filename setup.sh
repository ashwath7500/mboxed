# Import variables and functions
source etc/functions.sh
# Check to be root
need_root
#Pulling yamls
git clone https://github.com/cernbox/kuboxed.git  #add these in installations.
chmod -R 777 ./kuboxed
#Modifying yamls
sed -i 's/^\( *nodeApp:  *\)[^ ]*\(.*\)*$/\1minikube\2/' ./kuboxed/CERNBOX.yaml
sed -i 's/^\( *nodeApp:  *\)[^ ]*\(.*\)*$/\1minikube\2/' ./kuboxed/eos-storage-fst.template.yaml
sed -i 's/^\( *nodeApp:  *\)[^ ]*\(.*\)*$/\1minikube\2/' ./kuboxed/eos-storage-mgm.yaml
sed -i 's/^\( *nodeApp:  *\)[^ ]*\(.*\)*$/\1minikube\2/' ./kuboxed/LDAP.yaml
sed -i 's/^\( *nodeApp:  *\)[^ ]*\(.*\)*$/\1minikube\2/' ./kuboxed/SWAN.yaml
sed -i 's/swan-users/minikube/g' ./kuboxed/SWAN.yaml
NODE_NAME=$(hostname) #need to change for other drivers
sed -i 's@up2kube-cernbox.cern.ch@'"$NODE_NAME"'@' ./kuboxed/CERNBOX.yaml
sed -i 's@up2kube-swan.cern.ch@'"$NODE_NAME"'@' ./kuboxed/CERNBOX.yaml
sed -i 's@up2kube-cernbox.cern.ch@'"$NODE_NAME"'@' ./kuboxed/SWAN.yaml
sed -i 's@up2kube-swan.cern.ch@'"$NODE_NAME"'@' ./kuboxed/SWAN.yaml
Line_num=$(grep "SWAN_BACKEND_PORT"  ./kuboxed/CERNBOX.yaml -n | sed 's/^\([0-9]\+\):.*$/\1/')
Line_num=`expr $Line_num + 1`
sed -i ''"$Line_num"'s/^\( *value:  *\)[^ ]*\(.*\)*$/\1"10443"\2/' ./kuboxed/CERNBOX.yaml
sed -i 's/^\( *hostPort: &HTTP_PORT  *\)[^ ]*\(.*\)*$/\110080\2/' ./kuboxed/SWAN.yaml
sed -i 's/^\( *hostPort: &HTTPS_PORT  *\)[^ ]*\(.*\)*$/\110443\2/' ./kuboxed/SWAN.yaml
Line_num=$(grep "name: HTTP_PORT"  ./kuboxed/SWAN.yaml -n | sed 's/^\([0-9]\+\):.*$/\1/')
Line_num=`expr $Line_num + 1`
sed -i ''"$Line_num"'s/^\( *value:  *\)[^ ]*\(.*\)*$/\1"10080"\2/' ./kuboxed/SWAN.yaml
Line_num=$(grep "name: HTTPS_PORT"  ./kuboxed/SWAN.yaml -n | sed 's/^\([0-9]\+\):.*$/\1/')
Line_num=`expr $Line_num + 1`
sed -i ''"$Line_num"'s/^\( *value:  *\)[^ ]*\(.*\)*$/\1"10443"\2/' ./kuboxed/SWAN.yaml
sed -i 's:^cp.*$:cp ./kuboxed/eos-storage-fst.template.yaml $FNAME:g' ./kuboxed/eos-storage-fst.sh
#Pulling images
#TODO
#Starting minikube
sudo minikube start --driver=none --kubernetes-version=1.15.0
#Assigning label to minikube node
label_nodes
#Creation of persistant volumes
echo "Creating persistant volumes..."
create_volumes
#Deployement of Services
echo "Deploying Services..."
deploy_sciencebox
#adding users
echo "Adding dummy users..."
add_users
