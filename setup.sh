#Assigning labels to minikube node
sudo minikube start --driver=none
NODE_NAME=$(sudo kubectl get nodes | grep master | cut -d ' ' -f 1)
sudo kubectl label node $NODE_NAME nodeApp1=ldap
sudo kubectl label node $NODE_NAME nodeApp2=eos-mgm
sudo kubectl label node $NODE_NAME nodeApp3=eos-fst1
sudo kubectl label node $NODE_NAME nodeApp4=cernbox
sudo kubectl label node $NODE_NAME nodeApp5=cernbox
sudo kubectl label node $NODE_NAME nodeApp6=cernboxgateway
sudo kubectl label node $NODE_NAME nodeApp7=swan 
sudo kubectl label node $NODE_NAME nodeApp8=swan-users
sudo kubectl label node $NODE_NAME nodeApp9=eos-mq
#Creation of persistant volumes
sudo mkdir -p /mnt/ldap/userdb
sudo mkdir -p /mnt/ldap/config
sudo mkdir -p /mnt/cbox_shares_db/cbox_data
sudo mkdir -p /mnt/cbox_shares_db/cbox_MySQL
sudo mkdir -p /mnt/eos_namespace
sudo mkdir -p /mnt/fst_userdata
sudo mkdir -p /mnt/fst2_userdata
sudo mkdir -p /mnt/fst3_userdata
sudo chmod -rwx '/mnt'
#Deployement of Services
sudo kubectl apply -f BOXED.yaml
sudo kubectl apply -f LDAP.yaml
run=$'Running'
LDAP_PODNAME=$(sudo kubectl -n boxed get pods -o wide | grep ldap* | grep -o 'Running')
while  [ "$LDAP_PODNAME" != "$run" ] 
do
LDAP_PODNAME=$(sudo kubectl -n boxed get pods -o wide | grep ldap* | grep -o 'Running')
done
sudo kubectl apply -f eos-storage-mgm.yaml
Eos_PODNAME=$(sudo kubectl -n boxed get pods -o wide | grep eos-mgm | grep -o 'Running')
while [ "$Eos_PODNAME" != "$run" ]
do
Eos_PODNAME=$(sudo kubectl -n boxed get pods -o wide | grep eos-mgm | grep -o 'Running')
done
#bash eos-storage-fst.sh 1 eos-mgm.boxed.svc.cluster.local eos-mgm.boxed.svc.cluster.local docker default
#bash eos-storage-fst.sh 2 eos-mgm.boxed.svc.cluster.local eos-mgm.boxed.svc.cluster.local docker default
sudo kubectl apply -f eos-storage-fst1.yaml
sudo kubectl apply -f eos-storage-fst2.yaml
sudo kubectl apply -f eos-storage-fst3.yaml
sudo kubectl apply -f CERNBOX.yaml

#some uses
LDAP_PODNAME=$(sudo kubectl -n boxed get pods -o wide | grep ldap* | cut -d ' ' -f 1)
sudo kubectl exec -n boxed $LDAP_PODNAME -- bash /root/addusers.sh
 
