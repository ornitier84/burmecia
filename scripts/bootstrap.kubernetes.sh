#!/usr/bin/env bash
# -*- coding: utf-8 -*-

set -e

echo " [+] Adding Kubernetes repo"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

echo " [+] Disabling SELinux enforcement"
[[ "$(getenforce)" != "Disabled" ]] && setenforce 0

echo " [+] Disable Firewalld"
systemctl disable firewalld && systemctl stop firewalld

echo " [+] Installing Kubernetes & Docker"
yum install -y docker kubelet kubeadm kubectl kubernetes-cni

echo " [+] Ensure Docker and Kubelet are stopped"
systemctl stop docker
systemctl stop kubelet

echo " [+] Adding user 'vagrant' to Docker group"
usermod -a -G dockerroot vagrant

echo " [+] Changing Docker settings"
sed -e "s/OPTIONS='\(.\+\)'/OPTIONS='\1 --group=dockerroot'/g" /etc/sysconfig/docker > /etc/sysconfig/docker
echo 'DOCKER_STORAGE_OPTIONS="--storage-driver=overlay"' > /etc/sysconfig/docker-storage

echo " [+] Enable bridge-nf-{ip,ip6}tables"
[[ -z "$(grep 'net.bridge.bridge-nf-call-ip6tables' /etc/sysctl.conf)" ]] && echo "net.bridge.bridge-nf-call-ip6tables=1" >> /etc/sysctl.conf
[[ -z "$(grep 'net.bridge.bridge-nf-call-iptables' /etc/sysctl.conf)" ]] && echo "net.bridge.bridge-nf-call-iptables=1" >> /etc/sysctl.conf

echo " [!] Reloading sysctl.conf"
sysctl -p

echo " [!] Resetting Kubernetes data directories"
kubeadm reset

echo " [!] Launching Kubelet and Docker"
systemctl enable docker && systemctl start docker
systemctl enable kubelet && systemctl start kubelet
