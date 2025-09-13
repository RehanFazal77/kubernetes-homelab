#!/bin/bash
set -euo pipefail

LOG_FILE="$HOME/k8s-worker-setup.log"
echo "Logging setup to $LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

retry() {
    local n=1
    local max=5
    local delay=5
    while true; do
        "$@" && break || {
            if [[ $n -lt $max ]]; then
                ((n++))
                echo "Command failed. Attempt $n/$max:"
                sleep $delay;
            else
                echo "The command has failed after $n attempts."
                exit 1
            fi
        }
    done
}

install_if_missing() {
    for pkg in "$@"; do
        if ! dpkg -s $pkg >/dev/null 2>&1; then
            echo "Package $pkg not found. Installing..."
            sudo apt-get install -y $pkg
        else
            echo "Package $pkg is already installed."
        fi
    done
}

echo "=== Kubernetes Worker Node Setup Started ==="

# Pre-requisite check(system check)
echo "=== Checking dependencies ==="
sudo apt-get update -y
install_if_missing apt-transport-https ca-certificates curl gpg iptables iproute2

# 1. System Basics
echo "=== 1. Updating system ==="
sudo apt-get upgrade -y

# 2. Disable Swap, it create problem for k8s scheduler
echo "=== 2. Disabling swap ==="
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapon --show

# 3. Load Required Kernel Modules
echo "=== 3. Loading kernel modules ==="
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# 4. Set Sysctl Parameters 
echo "=== 4. Setting sysctl params ==="
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
sudo sysctl -w net.ipv4.ip_forward=1

# 5. Install Container Runtime (containerd)
echo "=== 5. Installing containerd ==="
sudo apt-get install -y containerd

sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

retry sudo systemctl restart containerd
sudo systemctl enable containerd
containerd config dump | grep SystemdCgroup

# 6. Add Kubernetes Repository(change this to the latest repo to install the current lastest version)
echo "=== 6. Adding Kubernetes repository ==="
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 7. Install kubelet, kubeadm, kubectl
echo "=== 7. Installing kubelet, kubeadm, kubectl ==="
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

# Configure kubelet to use systemd cgroup driver (AFTER kubelet installation)
echo "=== Configuring kubelet cgroup driver ==="
sudo mkdir -p /etc/systemd/system/kubelet.service.d
sudo tee /etc/systemd/system/kubelet.service.d/20-extra-args.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--cgroup-driver=systemd"
EOF
sudo systemctl daemon-reexec
retry sudo systemctl restart kubelet

# 8. Join the cluster
echo "=== 8. Join the Kubernetes cluster ==="
read -p "Paste the kubeadm join command from the control-plane node: " JOIN_CMD
retry $JOIN_CMD


echo "=== Kubernetes Worker Node Setup Completed Successfully! ==="
echo "Use 'kubectl get nodes' on the control-plane to verify this node has joined the cluster."
echo "All logs saved in $LOG_FILE"

