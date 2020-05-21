#Assigning labels to minikube node
minikube start --driver=docker
kubectl label node minikube nodeApp1=ldap
kubectl label node minikube nodeApp2=eos-mgm
kubectl label node minikube nodeApp3=eos-fstN
kubectl label node minikube nodeApp4=cernbox
kubectl label node minikube nodeApp5=cernbox
kubectl label node minikube nodeApp6=cernboxgateway
kubectl label node minikube nodeApp7=swan
kubectl label node minikube nodeApp8=swan-users
#Creation of persistant volumes
sudo mkdir -p /mnt/ldap/userdb
sudo mkdir -p /mnt/ldap/config
sudo mkdir -p /mnt/cbox_shares_db/cbox_data
sudo mkdir -p /mnt/cbox_shares_db/cbox_MySQL
sudo chmod -rwx '/mnt'
gnome-terminal -- minikube mount /mnt:/mnt
#Deployement of Services
kubectl apply -f BOXED.yaml
kubectl apply -f LDAP.yaml
