git clone https://github.com/libvirt/libvirt.git -b v4.7.0
cd libvirt
./bootstrap
yum install libpciaccess -y
yum install libpciaccess-devel.aarch64 -y
yum install yajl-devel.aarch64 -y
yum install device-mapper-devel.aarch64 -y
./autogen.sh
make -j4
make install

