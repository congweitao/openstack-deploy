#!/usr/bin/bash

install() {
yum  install --downloadonly --downloaddir=./rpms docker-ce
yum  install --downloadonly --downloaddir=./rpms kubectl kubelet kubeadm

yum install docker-ce -y
yum install kubelet kubectl kubeadm -y
}

pull_k8s_images() {
images=(kube-proxy:v1.15.0 kube-scheduler:v1.15.0 kube-controller-manager:v1.15.0 kube-apiserver:v1.15.0 etcd:3.3.10 pause:3.1 )
for imageName in ${images[@]} ; do    
    docker pull mirrorgooglecontainers/${imageName}
    docker pull coredns/coredns:1.3.1  # 这个在mirrorgooglecontainers中没有
    docker tag mirrorgooglecontainers/$imageName k8s.gcr.io/$imageName
    docker tag coredns/coredns:1.3.1 k8s.gcr.io/coredns:1.3.1
    docker rmi mirrorgooglecontainers/$imageName
    docker rmi coredns/coredns:1.3.1
done
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
