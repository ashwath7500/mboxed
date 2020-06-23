	#!/bin/bash
# Shared variables and functions


# ----- Variables ----- #
SUPPORTED_HOST_OS=(centos7)
SUPPORTED_NODE_TYPES=(master worker)

BASIC_SOFTWARE="curl wget git sudo "
DOCKER_VERSION="5:18.09.6~3-0~ubuntu-bionic"
KUBE_VERSION="1.15.0-00"

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
  fi
  fi      
}

# Install Docker
install_docker()
{
  echo ""
  echo "Installing Docker..." 

  if [[ "$HOST_OS" == "centos" ]]; then
    mkdir -p /var/lib/docker
    yum install -y yum-utils \
      device-mapper-persistent-data \
      lvm2
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    disable_selinux
    # See dependency issue: https://github.com/moby/moby/issues/33930
    yum install -y --setopt=obsoletes=0 \
      docker-ce${DOCKER_VERSION} \
      docker-ce-selinux${DOCKER_VERSION}
    systemctl enable docker && systemctl start docker
    systemctl status docker

  elif [[ "$HOST_OS" == "ubuntu" ]]; then
    echo ""
    # TODO: To be implemented
    sudo apt update
    sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt update
    sudo apt install docker-ce=${DOCKER_VERSION} -y
    systemctl enable docker && systemctl start docker
    systemctl status docker
  else
    echo "Unknown OS. Cannot continue."
    exit 1
  fi
}

#Check Kubernetes version
check_kube_version()
{
  ver=$'Version'
  if [ -x "$(command -v kubectl)" ]; then
  check=$(sudo kubectl version | grep -o 'Version')
  if [ "$check" == "$ver" ]; then
    check1="$(sudo kubectl version | grep -o "$KUBE_VERSION")"
    if [ "$check1" == "$KUBE_VERSION" ]; then
      echo "The required version is already installed."
    else
      read -p "You have a different version of kubectl installed which might not be able to run ScienceBox. Are you willing to change your version to $KUBE_VERSION ?(Y/N)" res
      if [[ "$res" == "NO" || "$res" == "No"|| "$res" == "no" || "$res" == "N" || "$res" == "n" ]]; then
        exit 1
      fi
    fi
  fi
  fi
}

#Install MiniKube
install_minikube()
{
  mkdir -p /usr/local/bin/  
  curl -L https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o /usr/local/bin/minikube
  chmod +x /usr/local/bin/minikube
  minikube version
}

# Install Kubernetes
install_kubernetes ()
{
  echo ""
  echo "Installing kubernetes..."

  if [[ "$HOST_OS" == "centos" ]]; then
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
	https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

    disable_selinux
    yum install -y \
      kubelet${KUBE_VERSION} \
      kubeadm${KUBE_VERSION} \
      kubectl${KUBE_VERSION}
    systemctl enable kubelet && systemctl start kubelet
    systemctl status kubelet

  elif [[ "$HOST_OS" ==  "ubuntu" ]]; then
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update -q
    sudo apt-get install -qy kubectl=${KUBE_VERSION}
    #systemctl enable kubelet && systemctl start kubelet
    #systemctl status kubelet
    kubectl version
  else
    echo "Unknown OS. Cannot continue."
    exit 1
  fi
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
  sudo kubectl label node $NODE_NAME nodeApp1=ldap
  sudo kubectl label node $NODE_NAME nodeApp2=eos-mgm
  sudo kubectl label node $NODE_NAME nodeApp3=eos-fst1
  sudo kubectl label node $NODE_NAME nodeApp4=cernbox
  sudo kubectl label node $NODE_NAME nodeApp5=cernbox
  sudo kubectl label node $NODE_NAME nodeApp6=cernboxgateway
  sudo kubectl label node $NODE_NAME nodeApp7=swan 
  sudo kubectl label node $NODE_NAME nodeApp8=swan-users
  sudo kubectl label node $NODE_NAME nodeApp9=eos-mq
}

#Creating persistant volumes
create_volumes()
{
  sudo mkdir -p /mnt/ldap/userdb
  sudo mkdir -p /mnt/ldap/config
  sudo mkdir -p /mnt/cbox_shares_db/cbox_data
  sudo mkdir -p /mnt/cbox_shares_db/cbox_MySQL
  sudo mkdir -p /mnt/eos_namespace
  sudo mkdir -p /mnt/fst_userdata
  sudo mkdir -p /mnt/fst2_userdata
  sudo mkdir -p /mnt/fst3_userdata
  sudo mkdir -p /mnt/jupyterhub_data
  sudo chmod -rwx '/mnt'
}

#Deployment of ScienceBox
deploy_sciencebox()
{
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
  bash eos-storage-fst.sh 1 eos-mgm.boxed.svc.cluster.local eos-mgm.boxed.svc.cluster.local docker default nodeApp3 eos-fst1
  bash eos-storage-fst.sh 2 eos-mgm.boxed.svc.cluster.local eos-mgm.boxed.svc.cluster.local docker default nodeApp3 eos-fst1
  bash eos-storage-fst.sh 3 eos-mgm.boxed.svc.cluster.local eos-mgm.boxed.svc.cluster.local docker default nodeApp3 eos-fst1
  sudo kubectl apply -f eos-storage-fst1.yaml
  sudo kubectl apply -f eos-storage-fst2.yaml
  sudo kubectl apply -f eos-storage-fst3.yaml
  sudo kubectl apply -f CERNBOX.yaml
  sudo kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=boxed:default
  sudo kubectl apply -f SWAN.yaml
}

#Adding users
add_users()
{
  LDAP_PODNAME=$(sudo kubectl -n boxed get pods -o wide | grep ldap* | cut -d ' ' -f 1)
  sudo kubectl exec -n boxed $LDAP_PODNAME -- bash /root/addusers.sh
}

#Pulling the dockcer images
pull_images()
{
docker pull gitlab-registry.cern.ch/cernbox/boxedhub/cernboxmysql:v1.0 -q
docker pull gitlab-registry.cern.ch/cernbox/boxedhub/cernbox:v1.4 -q
docker pull gitlab-registry.cern.ch/cernbox/boxedhub/cernboxgateway:v1.1 -q
docker pull gitlab-registry.cern.ch/cernbox/boxedhub/eos-storage:v0.9 -q
docker pull gitlab-registry.cern.ch/cernbox/boxedhub/eos-storage:v0.9 -q
docker pull gitlab-registry.cern.ch/cernbox/boxedhub/ldap:v0.2 -q
docker pull gitlab-registry.cern.ch/swan/docker-images/jupyterhub:v1.9 -q
docker pull gitlab-registry.cern.ch/cernbox/boxedhub/cvmfssquid:v0 -q
docker pull gitlab-registry.cern.ch/cernbox/boxedhub/eos-fuse:v0.8 -q
}

