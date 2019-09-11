#!/bin/bash


obs() {
virt-install \
--name centos7 \
--ram 8192 \
--disk path=/var/kvm/images/centos.img,format=qcow2 \
--vcpus 8 \
--os-type linux \
--os-variant rhel7 \
--graphics vnc \
--cdrom /var/lib/libvirt/images/CentOS-7-aarch64-Everything-1810.iso
}

virt-install --virt-type kvm --name centos --ram 8192 --vcpus 8 \
--disk /tmp/centos7.6.qcow2,format=qcow2 \
--network network=default \
--graphics vnc,listen=0.0.0.0 --noautoconsole \
--os-type=linux --os-variant=centos7.0 \
--location=/var/lib/libvirt/images/CentOS-7-aarch64-Everything-1810.iso
