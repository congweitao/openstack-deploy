#!/usr/bin/bash

yum  install --downloadonly --downloaddir=./rpms docker-ce
yum  install --downloadonly --downloaddir=./rpms kubectl kubelet kubeadm

yum install docker-ce -y
yum install kubelet kubectl kubeadm -y
