# Import variables and functions
source etc/common.sh
# Check to be root
need_root
#Starting minikube
sudo minikube start --driver=none --kubernetes-version=1.15.0
#Assigning labels to minikube node
label_nodes
#Creation of persistant volumes
create_volumes
#Deployement of Services
deploy_sciencebox
#adding users
add_users 
