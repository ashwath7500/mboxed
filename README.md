# Welcome to BOXED
### *MBoxed -- Single-host Demo Deployment on Minikube*

-----

Self-contained, containerized demo for next-generation cloud storage and computing services for scientific and general-purpose use:

 - CERNBox: https://cernbox.web.cern.ch
 - EOS: https://eos.web.cern.ch
 - SWAN: https://swan.web.cern.ch
 - CVMFS: https://cvmfs.web.cern.ch


Packaging done as part of GSoC 2020 by : Ashwath S
Mentors : Enrico Bocchi, Diogo Castro


-----

### Quick setup

 1. Install required software on the host:

    `sudo bash ./minikube_installations.sh`


 2. Setup and initialize all services: 

    `sudo bash ./setup.sh`

 3. Go to: https://yourhost.yourdomain



### Stop services

 Run the dedicated script:

    `sudo bash ./StopHost.sh`



### Remove Docker images and volumes

 Run the dedicated script:

    `sudo bash ./DeleteHost.sh


-----

#### *Enjoy and give feedback to CERN/IT and CERN/EP.*

-----


*\*Host OS Support*

Mboxed is Tested on Ubuntu 18.04 , but the scripts are designed to support any Linux Os.
Please provide feedback on the installation and setup.

