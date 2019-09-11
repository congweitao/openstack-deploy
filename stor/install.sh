#!/usr/bin/bash

tmp() {
yum --enablerepo=centos-openstack-stein,epel -y install openstack-swift-account openstack-swift-container openstack-swift-object xfsprogs rsync openssh-clients
mount -o noatime,nodiratime,nobarrier /dev/sdd /swift/node/device0/
chown -R swift. /swift/node
systemctl start rsyncd \
openstack-swift-account-auditor \
openstack-swift-account-replicator \
openstack-swift-account \
openstack-swift-container-auditor \
openstack-swift-container-replicator \
openstack-swift-container-updater \
openstack-swift-container \
openstack-swift-object-auditor \
openstack-swift-object-replicator \
openstack-swift-object-updater \
openstack-swift-object 
}

function configure_storage_node() {
mkfs.xfs -i size=1024 -s size=4096 /dev/sdd
mkdir -p /swift/node/device2
mount -o noatime,nodiratime,nobarrier /dev/sdd /swift/node/device2
chown -R swift. /swift/node
echo "/dev/sdd	/swift/node/device1	xfs 	noatime,nodiratime,nobarrier	0 0" >> /etc/fstab
rsync -avz 172.170.75.12:/etc/swift/*.gz /etc/swift/
chown swift. /etc/swift/*.gz
}
configure_storage_node
