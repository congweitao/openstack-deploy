#!/usr/bin/bash

install() {
yum  install --downloadonly --downloaddir=./rpms docker-ce
yum  install --downloadonly --downloaddir=./rpms kubectl kubelet kubeadm

yum install docker-ce -y
yum install kubelet kubectl kubeadm -y
}

pull_k8s_images() {
images=(kube-proxy-arm64:v1.15.1 kube-scheduler-arm64:v1.15.1 kube-controller-manager-arm64:v1.15.1 kube-apiserver-arm64:v1.15.1  )
for imageName in ${images[@]} ; do
    docker pull --platform arm64 mirrorgooglecontainers/${imageName}
    docker tag mirrorgooglecontainers/$imageName k8s.gcr.io/$imageName
    docker rmi mirrorgooglecontainers/$imageName
done
docker pull mirrorgooglecontainers/etcd-arm64:3.3.10 && docker tag k8s.gcr.io/etcd:3.3.10 && docker rmi mirrorgooglecontainers/etcd-arm64:3.3.10
docker pull --platform arm64 coredns/coredns:1.5.0 && docker tag coredns/coredns:1.5.0 k8s.gcr.io/coredns:1.3.1 && docker rmi coredns/coredns:1.5.0
docker pull --platform arm64  rancher/pause:3.1 && docker tag rancher/pause:3.1 k8s.gcr.io/pause:3.1 && docker rmi rancher/pause:3.1
}

cat >/etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
