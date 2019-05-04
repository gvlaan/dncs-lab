export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y tcpdump --assume-yes
apt install -y curl --assume-yes
ip addr add 192.168.10.1/24 dev eth1
ip link set eth1 up
ip route add 192.0.0.0/8 via 192.168.10.254
clear
echo "HOST-1-A done"
