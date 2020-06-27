	#!/bin/bash
# Shared variables and functions


# ----- Variables ----- #
SUPPORTED_HOST_OS=(centos7)
SUPPORTED_NODE_TYPES=(master worker)

BASIC_SOFTWARE="curl wget git sudo "
DOCKER_VERSION="18.09.9"
KUBE_VERSION="v1.15.0"
DRIVER="none"
OS_RELEASE="/etc/os-release"

# Versions







# ----- Functions ----- #

# Check to be root
need_root ()
{
  if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
  fi
}



# Disable SELinux if needed
disable_selinux ()
{
  test $(getenforce) == "Disabled" || setenforce 0
}



# (try to) Detect the OS
detect_os ()
{
  # TODO: not used
  source $OS_RELEASE
  HOST_OS=$ID
}



# Check if the node type was properly set
check_kube_node_type () 
{
  if [[ -z $KUBE_NODE_TYPE ]]; then
    echo "ERROR: KUBE_NOTE_TYPE not set."
    echo "Please set the node type with 'export KUBE_NODE_TYPE=<master||worker>'"
    echo "Cannot continue."
    exit -1
  fi

  # If the env var is set, check to have a valid name
  for ntype in ${SUPPORTED_NODE_TYPES[*]};
  do
    if [[ "$ntype" == "$KUBE_NODE_TYPE" ]]; then
      echo "Configuring this machine as ${ntype}."
      return
    fi
  done

  echo "ERROR: Invalid node type set."
  echo "Please set the node type with 'export KUBE_NODE_TYPE=<master||worker>'"
  echo "Cannot continue."
  exit -1
}



# Check if the host OS is supported
check_host_os_type ()
{
  if [[ -z $HOST_OS ]]; then
    echo "ERROR: HOST_OS not set."
    echo "Cannot continue."
    exit -1
  fi

  # If the env var is set, check to have a supported OS
  for ostype in ${SUPPORTED_HOST_OS[*]};
  do
    if [[ "$ostype" == "$HOST_OS" ]]; then
      return
    fi
  done

  echo "ERROR: Unsupported host os."
  echo "Supported OS: ${SUPPORTED_HOST_OS[*]}"
  echo "Cannot continue."
  exit -1
}



# Configure iptables to make the master reachable on TCP 6443 and TCP 10250
configure_iptables ()
{
# Completely disable iptables and firewalld
# There are issues with the DNS container and flannel
# k8s.io/dns/vendor/k8s.io/client-go/tools/cache/reflector.go:94: Failed to list *v1.Endpoints: Get https://10.96.0.1:443/api/v1/endpoints?resourceVersion=0: dial tcp 10.96.0.1:443: getsockopt: no route to host

  #TODO: Implement for Ubuntu
  systemctl stop iptables && systemctl disable iptables
  systemctl stop firewalld && systemctl disable firewalld

  # Properly set bridge-nf-call when SELinux is enforcing and firewalld is running
  sysctl net.bridge.bridge-nf-call-iptables=1
  sysctl net.bridge.bridge-nf-call-ip6tables=1

  # Set policy on FORWARD chain
  iptables --policy FORWARD ACCEPT      # See issue: https://github.com/kubernetes/kubernetes/issues/40182

: '''
# Could be of inspiration to configure at a finer grain, instead of disabling entire services
        TCP_PORTS_MASTER="2379 2380 6443 10250 10251 10252 10255 "
        TCP_PORTS_WORKER=" 10250 10255 "
        IFACE="eth0"
        echo ""
        echo "Configuring iptables..."
        # Different ports to be opened according to the node type
        if [[ "$1" == "master" ]]; then
                TCP_PORTS=$TCP_PORTS_MASTER
        elif [[ "$1" == "worker" ]]; then
                TCP_PORTS=$TCP_PORTS_WORKER
        else
                echo "WARNING: unknown node type. iptables left unchanged."
                TCP_PORTS=""
        fi
        # Add rules to iptables
        for port in $TCP_PORTS
        do
                iptables -I INPUT -i $IFACE -p tcp --dport $port -j ACCEPT
        done
        # Properly set bridge-nf-call when SELinux is enforcing and firewalld is running
        sysctl net.bridge.bridge-nf-call-iptables=1
        sysctl net.bridge.bridge-nf-call-ip6tables=1
'''
}


#Changing node labels
change_labels()
{
  sed -i 's/^\( *nodeApp:  *\)[^ ]*\(.*\)*$/\1minikube\2/' ./kuboxed/CERNBOX.yaml
  sed -i 's/^\( *nodeApp:  *\)[^ ]*\(.*\)*$/\1minikube\2/' ./kuboxed/eos-storage-fst.template.yaml
  sed -i 's/^\( *nodeApp:  *\)[^ ]*\(.*\)*$/\1minikube\2/' ./kuboxed/eos-storage-mgm.yaml
  sed -i 's/^\( *nodeApp:  *\)[^ ]*\(.*\)*$/\1minikube\2/' ./kuboxed/LDAP.yaml
  sed -i 's/^\( *nodeApp:  *\)[^ ]*\(.*\)*$/\1minikube\2/' ./kuboxed/SWAN.yaml
  sed -i 's/swan-users/minikube/g' ./kuboxed/SWAN.yaml
}

#Changing host names
change_hostname()
{
  NODE_NAME=$(hostname)
  sed -i 's@up2kube-cernbox.cern.ch@'"$NODE_NAME"'@' ./kuboxed/CERNBOX.yaml
  sed -i 's@up2kube-swan.cern.ch@'"$NODE_NAME"'@' ./kuboxed/CERNBOX.yaml
  sed -i 's@up2kube-cernbox.cern.ch@'"$NODE_NAME"'@' ./kuboxed/SWAN.yaml
  sed -i 's@up2kube-swan.cern.ch@'"$NODE_NAME"'@' ./kuboxed/SWAN.yaml
}

#Changing ports
change_ports()
{
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
}

#Additional required changes
other_changes()
{
  sed -i 's:^cp.*$:cp ./kuboxed/eos-storage-fst.template.yaml $FNAME:g' ./kuboxed/eos-storage-fst.sh #Modifying file path of fst template yaml
  sed -i 's/^\( *hostNetwork:  *\)[^ ]*\(.*\)*$/\1false\2/' ./kuboxed/SWAN.yaml #Changes to *not* run SWAN on hostnetwork
}
# Install the basic software
install_basics()
{
  echo ""
  echo "Installing the basics..."

  if [[ "$HOST_OS" == "centos" ]]; then
    yum install -y $BASIC_SOFTWARE
  elif [[ "$HOST_OS" == "ubuntu" ]]; then
    apt-get install -y $BASIC_SOFTWARE
  else
    echo "Unknown OS. Cannot continue."
    exit 1
  fi
}

#Check Docker version
check_docker_version()
{
  ver=$'version'
  if [ -x "$(command -v docker)" ]; then
  check=$(docker -v| grep -o 'version')
  if [ "$check" == "$ver" ]; then
    check1="$(docker -v| grep -o "$DOCKER_VERSION")"
    if [ "$check1" == "$DOCKER_VERSION" ]; then
      echo "The required version is already installed."
    else
      read -p "You have a different version of docker installed which might not be able to run ScienceBox. Are you willing to change your version to $DOCKER_VERSION ?(Y/N)" res
      if [[ "$res" == "NO" || "$res" == "No"|| "$res" == "no" || "$res" == "N" || "$res" == "n" ]]; then
        exit 1
      fi
    fi
    systemctl stop docker
  fi	
  fi      
}

# Install Docker
install_docker()
{
  echo ""
  echo "Installing Docker..." 
  sudo killall -q docker
  sudo killall -q containerd
  sudo groupadd -f docker

  mkdir -p /usr/local/bin/
  curl -L "https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz" -o docker.tgz
  tar zxvf docker.tgz
  chmod -R 777 docker
  sudo cp docker/* /usr/local/bin 
  sudo cp docker/* /usr/bin 
  rm docker.tgz
  rm -rf docker

  curl -L "https://raw.githubusercontent.com/moby/moby/master/contrib/init/systemd/docker.service" -o /etc/systemd/system/docker.service
  curl -L "https://raw.githubusercontent.com/moby/moby/master/contrib/init/systemd/docker.socket" -o /etc/systemd/system/docker.socket

  systemctl unmask docker.service
  systemctl unmask docker.socket
  systemctl start docker.service
  systemctl status docker --no-pager 
}

#Check Kubernetes version
check_kube_version()
{
  ver=$'Version'
  if [ -x "$(command -v kubectl)" ]; then
    check="$(sudo kubectl version | grep -o "$KUBE_VERSION")"
    if [ "$check" == "$KUBE_VERSION" ]; then
      echo "The required version of kubectl already installed."
    else
      read -p "You have a different version of kubectl installed which might not be able to run ScienceBox. Are you willing to change your version to $KUBE_VERSION ?(Y/N)" res
      if [[ "$res" == "NO" || "$res" == "No"|| "$res" == "no" || "$res" == "N" || "$res" == "n" ]]; then
        exit 1
      fi
    fi
  fi
}

#Install MiniKube
install_minikube()
{
  mkdir -p /usr/local/bin/  
  curl -L https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o minikube
  chmod +x minikube
  sudo cp minikube /usr/local/bin
  sudo cp minikube /usr/bin
  rm minikube
  minikube version
}

# Install Kubernetes
install_kubernetes ()
{
    mkdir -p /usr/local/bin/  
    curl -L "https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/bin/linux/amd64/kubectl" -o kubectl
    chmod +x kubectl
    sudo cp kubectl /usr/local/bin
    sudo cp kubectl /usr/bin
    rm kubectl
    kubectl version
}



# Configure kubelet with the cgroup driver used by docker
set_kubelet_cgroup_driver ()
{
  #TODO: Implement for Ubuntu

  echo ""
  echo "Configuring cgroup driver for kubelet service..."

  CGROUP_DRIVER=`docker info | grep -i cgroup | cut -d : -f 2 | tr -d " "`
  if [[ ! -f /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.MASTER ]]; then
    cp /etc/systemd/system/kubelet.service.d/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.MASTER
    sed -i "s/Environment=\"KUBELET_CGROUP_ARGS=--cgroup-driver=systemd\"/\n\#Environment=\"KUBELET_CGROUP_ARGS=--cgroup-driver=systemd\"\nEnvironment=\"KUBELET_CGROUP_ARGS=--cgroup-driver=${CGROUP_DRIVER}\"\n/" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  else
    sed "s/Environment=\"KUBELET_CGROUP_ARGS=--cgroup-driver=systemd\"/\n\#Environment=\"KUBELET_CGROUP_ARGS=--cgroup-driver=systemd\"\nEnvironment=\"KUBELET_CGROUP_ARGS=--cgroup-driver=${CGROUP_DRIVER}\"\n/" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.MASTER > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  fi

  systemctl daemon-reload
  service kubelet restart
}



# Start the cluster with Flannel pod network
start_kube_masternode ()
{
  #TODO: Implement for Ubuntu

  if [[ "$KUBE_NODE_TYPE" == "master" ]]; then
    echo ""
    echo "Initializing the cluster..."
    kubeadm init --pod-network-cidr=10.244.0.0/16 --token-ttl 0

    # This can be run as any user (root works as well)
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    # Use the Flannel pod network
    echo ""
    echo "Installing the Flannel pod network..."
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml

    # Restart kubelet to mak sure it picks up the extra config files
    # NOTE: This is mission-critical for hostPort and iptables mapping on kubernetes managed containers
    systemctl daemon-reload
    service kubelet restart
  fi
}
#Giving labels to nodes
label_nodes()
{
  NODE_NAME=$(sudo kubectl get nodes | grep master | cut -d ' ' -f 1)
  sudo kubectl label node $NODE_NAME nodeApp=minikube
}

#Creating persistant volumes
create_volumes()
{
  sudo mkdir -p /mnt/ldap/userdb
  sudo mkdir -p /mnt/ldap/config
  sudo mkdir -p /mnt/cbox_shares_db/cbox_data
  sudo mkdir -p /mnt/cbox_shares_db/cbox_MySQL
  sudo mkdir -p /mnt/eos_namespace
  sudo mkdir -p /mnt/fst1_userdata
  sudo mkdir -p /mnt/fst2_userdata
  sudo mkdir -p /mnt/fst3_userdata
  sudo mkdir -p /mnt/jupyterhub_data
  sudo chmod -rwx '/mnt'
  if [[ "$DRIVER" != "none" ]]; then
    sudo minikube mount /mnt:/mnt
  fi
}

#Deployment of ScienceBox
deploy_sciencebox()
{
  sudo kubectl apply -f ./kuboxed/BOXED.yaml
  sudo kubectl apply -f ./kuboxed/LDAP.yaml
  run=$'Running'
  # Waiting for ldap to start
  LDAP_PODNAME=$(sudo kubectl -n boxed get pods -o wide | grep ldap* | grep -o 'Running')
  while  [ "$LDAP_PODNAME" != "$run" ] 
  do
  LDAP_PODNAME=$(sudo kubectl -n boxed get pods -o wide | grep ldap* | grep -o 'Running')
  done
  sudo kubectl apply -f ./kuboxed/eos-storage-mgm.yaml
  # Waiting for EOS-MGM to start
  Eos_PODNAME=$(sudo kubectl -n boxed get pods -o wide | grep eos-mgm | grep -o 'Running')
  while [ "$Eos_PODNAME" != "$run" ]
  do
  Eos_PODNAME=$(sudo kubectl -n boxed get pods -o wide | grep eos-mgm | grep -o 'Running')
  done
  bash ./kuboxed/eos-storage-fst.sh 1 eos-mgm.boxed.svc.cluster.local eos-mgm.boxed.svc.cluster.local docker default
  bash ./kuboxed/eos-storage-fst.sh 2 eos-mgm.boxed.svc.cluster.local eos-mgm.boxed.svc.cluster.local docker default
  bash ./kuboxed/eos-storage-fst.sh 3 eos-mgm.boxed.svc.cluster.local eos-mgm.boxed.svc.cluster.local docker default
  # Updating fst userdata paths
  sed -i 's/fst_userdata/fst1_userdata/g' eos-storage-fst1.yaml
  sed -i 's/fst_userdata/fst2_userdata/g' eos-storage-fst2.yaml
  sed -i 's/fst_userdata/fst3_userdata/g' eos-storage-fst3.yaml
  sudo kubectl apply -f eos-storage-fst1.yaml
  sudo kubectl apply -f eos-storage-fst2.yaml
  sudo kubectl apply -f eos-storage-fst3.yaml
  sudo kubectl apply -f ./kuboxed/CERNBOX.yaml
  sudo kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=boxed:default
  sudo kubectl apply -f ./kuboxed/SWAN.yaml
  # Waiting for SWAN to start
  SWAN_PODNAME=$(sudo kubectl -n boxed get pods -o wide | grep swan | grep -v  daemon | grep -o 'Running')
  while  [ "$SWAN_PODNAME" != "$run" ] 
  do
  SWAN_PODNAME=$(sudo kubectl -n boxed get pods -o wide | grep swan | grep -v  daemon | grep -o 'Running')
  done
  SWAN_PODNAME=$(sudo kubectl -n boxed get pods -o wide | grep swan | grep -v  daemon | cut -d ' ' -f 1)
  # Making changes to jupyterhub configurations
  sudo kubectl exec -n boxed $SWAN_PODNAME -- sed -i 's/"0.0.0.0"/"127.0.0.1"/g' /srv/jupyterhub/jupyterhub_config.py
  sudo kubectl exec -n boxed $SWAN_PODNAME -- sed -i '/8080/a hub_ip='"$HOSTNAME"'' /srv/jupyterhub/jupyterhub_config.py
}

# Adding users
add_users()
{
  LDAP_PODNAME=$(sudo kubectl -n boxed get pods -o wide | grep ldap* | cut -d ' ' -f 1)
  sudo kubectl exec -n boxed $LDAP_PODNAME -- bash /root/addusers.sh
}

# Pulling the dockcer images
pull_images()
{
  # Creating a list of images required for each of the yaml files
  imgs=$(grep 'image:' ./kuboxed/SWAN.yaml | sed  's/image://')
  # Iterating and pulling the images
  for img in $imgs
  do
  docker pull $img
  done
  imgs=$(grep 'image:' ./kuboxed/LDAP.yaml | sed  's/image://')
  for img in $imgs
  do
  docker pull $img
  done
  imgs=$(grep 'image:' ./kuboxed/eos-storage-mgm.yaml | sed  's/image://')
  for img in $imgs
  do
  docker pull $img
  done
  imgs=$(grep 'image:' ./kuboxed/eos-storage-fst.template.yaml | sed  's/image://')
  for img in $imgs
  do
  docker pull $img
  done
  imgs=$(grep 'image:' ./kuboxed/CERNBOX.yaml | sed  's/image://')
  for img in $imgs
  do
  docker pull $img
  done
}

