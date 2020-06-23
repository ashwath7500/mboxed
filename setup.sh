# Import variables and functions
source etc/common.sh
# Check to be root
need_root
#Starting minikube
sudo minikube start --driver=none --kubernetes-version=1.15.0
#Prepull images
echo "Pre-Pulling images..."
pull_images
#Assigning labels to minikube node
echo "Labels are being assigned..."
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
