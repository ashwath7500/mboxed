#Assigning labels to minikube node
minikube start --driver=docker --cpus 8 --memory 11894
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
gnome-terminal -- minikube mount $HOME/mnt:/mnt
#Deployement of Services
kubectl apply -f BOXED.yaml
kubectl apply -f LDAP.yaml
