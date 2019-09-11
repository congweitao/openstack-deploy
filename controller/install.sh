#!/usr/bin/bash

function keystone(){
sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/CentOS-OpenStack-stein.repo

yum --enablerepo=centos-openstack-stein -y install mariadb-server
yum --enablerepo=centos-openstack-stein -y install rabbitmq-server memcached
systemctl start mariadb
systemctl enable mariadb
mysql_secure_installation 
systemctl restart rabbitmq-server.service 
systemctl restart memcached.service 
rabbitmqctl add_user openstack password 
rabbitmqctl set_permissions openstack ".*" ".*" ".*" 
yum --enablerepo=centos-openstack-stein,epel -y install openstack-keystone openstack-utils python-openstackclient httpd mod_wsgi
su -s /bin/bash keystone -c "keystone-manage db_sync"
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone 
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
export controller=172.170.75.11
keystone-manage bootstrap --bootstrap-password huawei --bootstrap-admin-url http://$controller:5000/v3/ --bootstrap-internal-url http://$controller:5000/v3/ --bootstrap-public-url http://$controller:5000/v3/ --bootstrap-region-id RegionOne
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl start httpd
systemctl enable httpd
cat > keystonerc << EOF
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=huawei
export OS_AUTH_URL=http://172.170.75.11:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export PS1='[\u@\h \W(keystone)]\$ '
EOF
openstack project create --domain default --description "Service Project" service
openstack project list
}

function install_glance(){
openstack user create --domain default --project service --password huawei glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image service" image
export controller=172.170.75.11
openstack endpoint create --region RegionOne image public http://$controller:9292
openstack endpoint create --region RegionOne image internal http://$controller:9292
openstack endpoint create --region RegionOne image admin http://$controller:9292
yum --enablerepo=centos-openstack-stein,epel -y install openstack-glance
}

function install_nova(){
openstack user create --domain default --project service --password huawei nova
openstack role add --project service --user nova admin
openstack user create --domain default --project service --password huawei placement
openstack role add --project service --user placement admin
openstack service create --name nova --description "OpenStack Compute service" compute 
openstack service create --name placement --description "OpenStack Compute Placement service" placement
export controller=172.170.75.11
openstack endpoint create --region RegionOne compute public http://$controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal http://$controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin http://$controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne placement public http://$controller:8778
openstack endpoint create --region RegionOne placement internal http://$controller:8778
openstack endpoint create --region RegionOne placement admin http://$controller:8778
cat > /etc/nova/nova.conf <<EOF
# create new
[DEFAULT]
# define own IP
my_ip = 172.170.75.11
state_path = /var/lib/nova
enabled_apis = osapi_compute,metadata
log_dir = /var/log/nova
# RabbitMQ connection info
transport_url = rabbit://openstack:password@172.170.75.11

[api]
auth_strategy = keystone

# Glance connection info
[glance]
api_servers = http://172.170.75.11:9292

[oslo_concurrency]
lock_path = /tmp
# MariaDB connection info
[api_database]
connection = mysql+pymysql://nova:huawei@172.170.75.11/nova_api

[database]
connection = mysql+pymysql://nova:huawei@172.170.75.11/nova

# Keystone auth info
[keystone_authtoken]
www_authenticate_uri = http://172.170.75.11:5000
auth_url = http://172.170.75.11:5000
memcached_servers = 172.170.75.11:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = huawei

[placement]
auth_url = http://172.170.75.11:5000
os_region_name = RegionOne
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = placement
password = huawei

[placement_database]
connection = mysql+pymysql://nova:huawei@172.170.75.11/nova_placement

[wsgi]
api_paste_config = /etc/nova/api-paste.ini
EOF
chmod 640 /etc/nova/nova.conf
chgrp nova /etc/nova/nova.conf
}

function install_neutron() {
openstack user create --domain default --project service --password huawei neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking service" network 
export controller=172.170.75.11
openstack endpoint create --region RegionOne network public http://$controller:9696
openstack endpoint create --region RegionOne network internal http://$controller:9696
openstack endpoint create --region RegionOne network admin http://$controller:9696
cat > /etc/neutron/neutron.conf <<EOF
# create new
[DEFAULT]
core_plugin = ml2
service_plugins = router
auth_strategy = keystone
state_path = /var/lib/neutron
dhcp_agent_notification = True
allow_overlapping_ips = True
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
# RabbitMQ connection info
transport_url = rabbit://openstack:password@172.170.75.11

# Keystone auth info
[keystone_authtoken]
www_authenticate_uri = http://172.170.75.11:5000
auth_url = http://172.170.75.11:5000
memcached_servers = 172.170.75.11:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = huawei

# MariaDB connection info
[database]
connection = mysql+pymysql://neutron:huawei@172.170.75.11/neutron_ml2

# Nova connection info
[nova]
auth_url = http://172.170.75.11:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = huawei

[oslo_concurrency]
lock_path = \$state_path/tmp
EOF
}

function add_users() {
# add users in keystone who can use openstack system
openstack project create --domain default --description "TaiShan Project" taishan
openstack user create --domain default --project taishan --password huawei serverworld
openstack role create CloudUser
openstack role add --project taishan --user serverworld CloudUser
openstack flavor create --id 0 --vcpus 1 --ram 2048 --disk 10 m1.small
}

function create_virtual_network() {
projectID=$(openstack project list | grep service | awk '{print $2}')
openstack network create --project $projectID --share --provider-network-type flat --provider-physical-network physnet1 sharednet1 
openstack subnet create subnet1 --network sharednet1 \
--project $projectID --subnet-range 172.170.75.0/24 \
--allocation-pool start=172.170.75.200,end=172.170.75.254 \
--gateway 172.170.75.3 --dns-nameserver 8.8.8.8
openstack network list
openstack subnet list
}
function create_security_group() {
openstack security group create secgroup1
ssh-keygen -q -N ""
openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
openstack keypair list
netID=$(openstack network list | grep sharednet1 | awk '{ print $2 }') 
openstack server create --flavor m1.small --image CentOS7 --security-group secgroup1 --nic net-id=$netID --key-name mykey CentOS_7
openstack server list
}

# install and congfigure openstack block storage (cinder)
function cinder_add_user() {
    openstack user create --domain default --project service --password huawei cinder
    openstack role add --project service --user cinder admin
    openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3
    export controller=172.170.75.11
    openstack endpoint create --region RegionOne volumev3 public http://$controller:8776/v3/%\(tenant_id\)s
    openstack endpoint create --region RegionOne volumev3 internal http://$controller:8776/v3/%\(tenant_id\)s
    openstack endpoint create --region RegionOne volumev3 admin http://$controller:8776/v3/%\(tenant_id\)s
}

function cinder_install() {
yum --enablerepo=centos-openstack-stein,epel -y install openstack-cinder
mv /etc/cinder/cinder.conf /etc/cinder/cinder.conf.bak
cat > /etc/cinder/cinder.conf << EOF
# create new
[DEFAULT]
# define own IP address
my_ip = 172.170.75.11
log_dir = /var/log/cinder
state_path = /var/lib/cinder
auth_strategy = keystone
# RabbitMQ connection info
transport_url = rabbit://openstack:huawei@172.170.75.11
enable_v3_api = True

# MariaDB connection info
[database]
connection = mysql+pymysql://cinder:huawei@172.170.75.11/cinder

# Keystone auth info
[keystone_authtoken]
www_authenticate_uri = http://172.170.75.11:5000
auth_url = http://172.170.75.11:5000
memcached_servers = 172.170.75.11:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = cinder
password = huawei

[oslo_concurrency]
lock_path = \$state_path/tmp
EOF
chmod 640 /etc/cinder/cinder.conf
chgrp cinder /etc/cinder/cinder.conf
su -s /bin/bash cinder -c "cinder-manage db sync"
systemctl start openstack-cinder-api openstack-cinder-scheduler
systemctl enable openstack-cinder-api openstack-cinder-scheduler
}

function cinder_volume_install() {
yum --enablerepo=centos-openstack-stein,epel -y install openstack-cinder python2-crypto targetcli
mv /etc/cinder/cinder.conf /etc/cinder/cinder.conf.org
cat > /etc/cinder/cinder.conf << EOF
# create new
[DEFAULT]
# define own IP address
my_ip = 172.170.75.13
log_dir = /var/log/cinder
state_path = /var/lib/cinder
auth_strategy = keystone
# RabbitMQ connection info
transport_url = rabbit://openstack:huawei@172.170.75.11
# Glance connection info
glance_api_servers = http://172.170.75.11:9292
enable_v3_api = True

# MariaDB connection info
[database]
connection = mysql+pymysql://cinder:huawei@172.170.75.11/cinder

# Keystone auth info
[keystone_authtoken]
www_authenticate_uri = http://172.170.75.11:5000
auth_url = http://172.170.75.11:5000
memcached_servers = 172.170.75.11:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = cinder
password = huawei

[oslo_concurrency]
lock_path = \$state_path/tmp
EOF
chmod 640 /etc/cinder/cinder.conf
chgrp cinder /etc/cinder/cinder.conf
systemctl start openstack-cinder-volume
systemctl enable openstack-cinder-volume
}

# on controller node
function configure_swift() {
# add swift user
openstack user create --domain default --project service --password huawei swift
# add swift user in admin role
openstack role add --project service --user swift admin
openstack service create --name swift --description "OpenStack Object Storage" object-store 
export swift_proxy=172.170.75.12
openstack endpoint create --region RegionOne object-store public http://$swift_proxy:8080/v1/AUTH_%\(tenant_id\)s
openstack endpoint create --region RegionOne object-store internal http://$swift_proxy:8080/v1/AUTH_%\(tenant_id\)s 
openstack endpoint create --region RegionOne object-store admin http://$swift_proxy:8080/v1
}

configure_swift
