#!/usr/bin/bash

function install_openstack() {
# repository installation
yum install centos-release-openstack-stein -y
sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/CentOS-OpenStack-stein.repo
}

function configure_swift_ring() {
swift-ring-builder /etc/swift/account.builder create 12 3 1 
swift-ring-builder /etc/swift/container.builder create 12 3 1 
swift-ring-builder /etc/swift/object.builder create 12 3 1
swift-ring-builder /etc/swift/account.builder add r0z0-172.170.75.13:6202/device0 100 
swift-ring-builder /etc/swift/container.builder add r0z0-172.170.75.13:6201/device0 100 
swift-ring-builder /etc/swift/object.builder add r0z0-172.170.75.13:6200/device0 100 
swift-ring-builder /etc/swift/account.builder add r1z1-172.170.75.14:6202/device1 100 
swift-ring-builder /etc/swift/container.builder add r1z1-172.170.75.14:6201/device1 100 
swift-ring-builder /etc/swift/object.builder add r1z1-172.170.75.14:6200/device1 100 
swift-ring-builder /etc/swift/account.builder add r2z2-172.170.75.15:6202/device2 100 
swift-ring-builder /etc/swift/container.builder add r2z2-172.170.75.15:6201/device2 100 
swift-ring-builder /etc/swift/object.builder add r2z2-172.170.75.15:6200/device2 100 
swift-ring-builder /etc/swift/account.builder rebalance 
swift-ring-builder /etc/swift/container.builder rebalance 
swift-ring-builder /etc/swift/object.builder rebalance 
chown swift. /etc/swift/*.gz 
systemctl start openstack-swift-proxy
systemctl enable openstack-swift-proxy
}

configure_swift_ring
