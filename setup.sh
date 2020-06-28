# Import variables and functions
source etc/functions.sh

# Preliminary checks
echo ""
echo "Preliminary checks..."
need_root

# Pulling yamls
echo ""
echo "Pulling kuboxed..."
git clone https://github.com/cernbox/kuboxed.git
chmod -R 777 ./kuboxed


# Starting minikube
echo ""
echo "Starting minikube..."
sudo minikube start --driver=$DRIVER --kubernetes-version=1.15.0 --disk-size=50138MB --force

# Modifying yamls
echo ""
echo "Modyfing kuboxed..."
change_labels
change_hostname
change_ports
other_changes

# Pulling images
echo ""
echo "Pulling images..."
#pull_images

# Assigning label to minikube node
echo ""
echo "Assinging label to node..."
label_nodes

# Creation of persistant volumes
echo ""
echo "Creating persistant volumes..."
create_volumes

# Deployement of Services
echo ""
echo "Deploying Services..."
deploy_sciencebox

# adding users
echo ""
echo "Adding dummy users..."
add_users

echo ""
echo "Setup Completed."
