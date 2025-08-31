# Kubernetes Homelab: Multi-Node Cluster with Multipass VMs

## Project Overview

This project demonstrates a **hands-on Kubernetes homelab** using **Multipass** virtual machines for creating a multi-node cluster. The cluster is built for learning and experimentation, and simulates a real-world Kubernetes environment.

The setup includes:

- **1 Control-Plane Node**
- **2 Worker Nodes**

Each VM runs **Ubuntu 24.04 LTS** with **containerd** as the container runtime, and **Flannel** is used as the CNI plugin for pod networking.

---

## Tools & Technologies

- **VM Management**: [Multipass](https://multipass.run/)  
- **Operating System**: Ubuntu 24.04 LTS  
- **Container Runtime**: containerd v1.7.x  
- **Kubernetes**: v1.34.0  
- **Networking**: Flannel CNI  
- **Kube Tools**: kubeadm, kubelet, kubectl  

---

## Cluster Architecture

            +-------------------------+
             | Control Plane Node     |
             | (kube-apiserver, etcd) |
             +-----------+-------------+
                         |
      ----------------------------------------
      |                                      |
    +---------------------+ +---------------------+
        | Worker Node 1 | | Worker Node 2 |
      | (Pods + workloads) | | (Pods + workloads) |
    +---------------------+ +---------------------+



- Control-plane node manages scheduling, API server, and etcd.  
- Worker nodes run workloads and handle pod networking through Flannel.

---

## Node Roles

Example of node roles after labeling worker nodes:

```bash
root@rehanfazal-control-plane:~# kubectl get nodes -o wide 
NAME                       STATUS   ROLES           AGE    VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
rehanfazal-control-plane   Ready    control-plane   103m   v1.34.0   10.145.93.35    <none>        Ubuntu 24.04.3 LTS   6.8.0-71-generic   containerd://1.7.27
rehanfazal-workernode      Ready    worker-node     51m    v1.34.0   10.145.93.242   <none>        Ubuntu 24.04.3 LTS   6.8.0-71-generic   containerd://1.7.27
rehanfazal-workernode1     Ready    worker-node     22m    v1.34.0   10.145.93.213   <none>        Ubuntu 24.04.3 LTS   6.8.0-71-generic   containerd://1.7.27
```


**#Automated Setup Scripts**

**This homelab uses shell scripts to automate the installation of Kubernetes components on each node.**
1. Control-Plane Node Script
* Script: controlplane_script.sh
* Run on the control-plane VM only.
* Installs container runtime, kubeadm, kubelet, kubectl.
* Initializes the cluster with kubeadm init.
* Deploys Flannel CNI and configures the kubelet.

 On the control-plane VM
```bash
chmod +x controlplane_script.sh
./controlplane_script.sh
```
2. Worker Node Script
* Script: workernode_script.sh
* Run separately on each worker VM.
* Installs container runtime, kubeadm, kubelet.
* Disables swap, sets kernel modules and sysctl.
* Prompts to paste the kubeadm join command from the control-plane node.

# On each worker VM
```bash
chmod +x workernode_script.sh
./workernode_script.sh
```

Both scripts are designed to run independently on separate nodes and automate all necessary setup steps.


**Setup Overview**
Provision VMs with Multipass
```bash
            multipass launch -n <control-plane-name> -c 2 -m 2G -d 20G
            multipass launch -n <workernode-name> -c 2 -m 2G -d 20G
            multipass launch -n <workernode1-name> -c 2 -m 2G -d 20G
```

Run Control-Plane Script on control-plane VM.
Run Worker Node Script on each worker VM and paste the join command from control-plane.

Verify Cluster from control-plane:
            kubectl get nodes -o wide
            kubectl get pods -A

**Learning Outcomes**
* Hands-on experience with multi-node Kubernetes cluster setup
* Understanding container runtimes, kubelet configuration, and networking (CNI)
* Manual worker node joining for better comprehension
* Node labeling and role management
* Practice in cluster verification and basic troubleshooting
* Exposure to automation with shell scripts for consistent cluster setup

Author
Rehan Fazal
GitHub: rehanfazal77
