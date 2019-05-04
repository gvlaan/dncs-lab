export DEBIAN_FRONTEND=noninteractive
apt-get update -y
#apt-get upgrade --assume-yes
apt-get install -y tcpdump --assume-yes
apt-get install -y apt-transport-https ca-certificates curl software-properties-common --assume-yes --force-yes
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce=18.06.1~ce~3-0~ubuntu jq --assume-yes --force-yes
ip addr add 192.168.30.1/30 dev eth1
ip link set eth1 up
ip route add 192.0.0.0/8 via 192.168.30.2
docker kill $(docker ps -q)
docker rm $(docker ps -aq)
docker pull nginx
mkdir -p ~/docker-nginx/html
echo "<html>
<head><title>DNCS ASSIGNMENT</title></head>
<body>
<p>TEST HOST-2-C DONE<p>
</body>
</html>" > ~/docker-nginx/html/index.html
docker run --name docker-nginx -p 80:80 -d -v ~/docker-nginx/html:/usr/share/nginx/html nginx
clear
echo "HOST-2-C done"
