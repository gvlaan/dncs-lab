# DNCS-LAB | Assignment


University of Trento - Information and Communication Engineering

_Description_: This repository contains the Vagrant files and the scripts required to run the virtual lab environment used in the DNCS course.

_Assignment_: Based the V​agrantfile ​and the provisioning scripts available at: https://github.com/dustnic/dncs-lab​ the candidate is required to design a functioning network where any host configured and attached to​ r​outer-1​ (through ​switch​) can browse a website hosted on host-2-c.
The subnetting needs to be designed to accommodate the following requirement (no need to create more hosts than the one described in the vagrantfile):
- Up to 130 hosts in the same subnet of ​host-1-a
- Up to 25 hosts in the same subnet of h​ost-1-b
- Consume as few IP addresses as possible


## Requirements

-   10GB disk storage
-   2GB free RAM
-   Virtualbox (<https://www.virtualbox.org>)
-   Vagrant (<https://www.vagrantup.com>)
-   Internet

### Network map

    VAGRANT
    MANAGEMENT

     +------+
     |      |
     |      +-------------------------------------------------+
     |      |                                             eth0|
     |      |           +----------+                     +----+-----+
     |      |           |          |                     |          |
     |      |       eth0|          |                     |          |
     |      +-----------+ ROUTER 1 +---------------------+ ROUTER 2 |
     |      |           |          |eth2             eth2|          |
     |      |           |          |                     |          |
     |      |           +----+-----+                     +----+-----+
     |      |                |eth1                            |eth1
     |      |                |                                |
     |      |                |eth1                            |eth1
     |      |       +--------+----------+                 +---+----+
     |      |   eth0|                   |                 |        |
     |      +-------+      SWITCH       |                 | HOST C |
     |      |       |                   |                 |        |
     |      |       +----+----------+---+                 +---+----+
     |      |            |eth2      |eth3                 eth0|
     |      |            |eth1      |eth1                     |
     |      |       +----+---+  +---+----+                    |
     |      |   eth0|        |  |        |                    |
     |      +-------+ HOST A |  | HOST B |                    |
     |      |       |        |  |        |                    |
     |      |       +--------+  +---+----+                    |
     |      |                       |eth0                     |
     |      +-----------------------+                         |
     |      +-------------------------------------------------+
     +------+

### Subnets

The network is divided in 4 different subnets:

| Subnet | Devices                   | Netmask         | Description                          |
| ------ | ------------------------- | --------------- | ------------------------------------ |
| A      | `host-1-a` and `router-1` | 255.255.255.0   | IP addresses for 254 different hosts |
| B      | `host-1-b` and `router-1` | 255.255.255.224 | IP addresses for 30 different hosts  |
| C      | `router-1` and `router-2` | 255.255.255.252 | IP addresses for 2 different hosts   |
| D      | `router-2` and `host-2-c` | 255.255.255.252 | IP addresses for 2 different hosts   |

### VLANs

VLANs allow to connect different subnets via unique port. In the assignment the virtual subnet containing `host-1-a` and the one containing `host-1-b` must be separated in terms of broadcasts area on the switch, so using VLANs the switch can be split in two virtual switches.
I set up VLANs for the networks A and B.

| VLAN ID | Subnet | Interface |
| ------- | ------ | --------- |
| 10      | A      | eth1.10   |
| 20      | B      | eth1.20   |

### Interface-IP mapping

| Device   | Interface | IP                 | Subnet |
| -------- | --------- | ------------------ | ------ |
| host-1-a | eth1      | 192.168.10.1/24    | A      |
| router-1 | eth1.10   | 192.168.10.254/24  | A      |
| host-1-b | eth1      | 192.168.20.1/27    | B      |
| router-1 | eth1.20   | 192.168.20.30/27   | B      |
| host-2-c | eth1      | 192.168.30.1/30    | C      |
| router-2 | eth1      | 192.168.30.2/30    | C      |
| router-1 | eth2      | 192.168.255.253/30 | D      |
| router-2 | eth2      | 192.168.255.254/30 | D      |


### Vagrant file and provisioning scripts

The project folder contains the Vagrant file, used to set up all the Virtual Machines (all based on Trusty64), and the provisioning scripts for each VM.

#### Router 1

Here the code used in the Vagrantfile to create the VM with two different interfaces. Then it will execute the provisioning script "router-1.sh"
  ```ruby
    config.vm.define "router-1" do |router1|
      router1.vm.box = "minimal/trusty64"
      router1.vm.hostname = "router-1"
      router1.vm.network "private_network", virtualbox__intnet: "broadcast_router-south-1", auto_config: false
      router1.vm.network "private_network", virtualbox__intnet: "broadcast_router-inter", auto_config: false
      router1.vm.provision "shell", path: "router-1.sh"
    end
  ```
##### Provisioning script

VLAN configuration to trunk the connection between `router-1` and `switch`:
  ```bash
    ip link add link eth1 name eth1.10 type vlan id 10
    ip link add link eth1 name eth1.20 type vlan id 20
  ```
IP addresses assignment:
  ```bash
    ip addr add 192.168.10.254/24 dev eth1.10
    ip addr add 192.168.20.30/27 dev eth1.20
    ip addr add 192.168.255.253/30 dev eth2
  ```
Interfaces set up:
  ```bash
    ip link set eth1 up
    ip link set eth1.10 up
    ip link set eth1.20 up
    ip link set eth2 up
  ```
IP forwarding and FRRouting using OSPF protocol:
  ```bash
    sysctl net.ipv4.ip_forward=1
    sed -i 's/zebra=no/zebra=yes/g' /etc/frr/daemons
    sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
    service frr restart
    vtysh -c 'configure terminal' -c 'interface eth2' -c 'ip ospf area 0.0.0.0'
    vtysh -c 'configure terminal' -c 'router ospf' -c 'redistribute connected'
  ```

#### Router 2

Here the code used in the Vagrantfile to create the VM with two different interfaces. Then it will execute the provisioning script "router-2.sh"
  ```ruby
    config.vm.define "router-2" do |router2|
      router2.vm.box = "minimal/trusty64"
      router2.vm.hostname = "router-2"
      router2.vm.network "private_network", virtualbox__intnet: "broadcast_router-south-2", auto_config: false
      router2.vm.network "private_network", virtualbox__intnet: "broadcast_router-inter", auto_config: false
      router2.vm.provision "shell", path: "router-2.sh"
    end
  ```
##### Provisioning script

IP addresses assignment:
  ```bash
    ip addr add 192.168.30.2/30 dev eth1
    ip addr add 192.168.255.254/30 dev eth2
  ```
Interfaces set up:
  ```bash
    ip link set eth1 up
    ip link set eth2 up
  ```
IP forwarding and FRRouting using OSPF protocol:
  ```bash
  sysctl net.ipv4.ip_forward=1
  sed -i 's/zebra=no/zebra=yes/g' /etc/frr/daemons
  sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
  service frr restart
  vtysh -c 'configure terminal' -c 'interface eth2' -c 'ip ospf area 0.0.0.0'
  vtysh -c 'configure terminal' -c 'router ospf' -c 'redistribute connected'
  ```

#### Switch

Here the code used in the Vagrantfile to create the VM with three different interfaces. Then it will execute the provisioning script "switch.sh"
  ```ruby
    config.vm.define "switch" do |switch|
      switch.vm.box = "minimal/trusty64"
      switch.vm.hostname = "switch"
      switch.vm.network "private_network", virtualbox__intnet: "broadcast_router-south-1", auto_config: false
      switch.vm.network "private_network", virtualbox__intnet: "broadcast_host_a", auto_config: false
      switch.vm.network "private_network", virtualbox__intnet: "broadcast_host_b", auto_config: false
      switch.vm.provision "shell", path: "switch.sh"
  end
  ```
##### Provisioning script

Set up a bridge (named switch) and add the interfaces to it: _eth1_ and _eth2_ are used for VLAN
  ```bash
    ovs-vsctl add-br switch
    ovs-vsctl add-port switch eth1
    ovs-vsctl add-port switch eth2 tag=10
    ovs-vsctl add-port switch eth3 tag=20
  ```
Interfaces and ovs-system set up:
  ```bash
    ip link set eth1 up
    ip link set eth2 up
    ip link set eth3 up
    ip link set dev ovs-system up
  ```

#### Host A

Here the code used in the Vagrantfile to create the VM with one interface. Then it will execute the provisioning script "host-1-a.sh".
  ```ruby
    config.vm.define "host-1-a" do |hosta|
      hosta.vm.box = "minimal/trusty64"
      hosta.vm.hostname = "host-1-a"
      hosta.vm.network "private_network", virtualbox__intnet: "broadcast_host_a", auto_config: false
      hosta.vm.provision "shell", path: "host-1-a.sh"
    end
  ```
##### Provisioning script

IP address configuration on _eth1_ and interface set up:
  ```bash
    ip addr add 192.168.10.1/24 dev eth1
    ip link set eth1 up
  ```
Set a static route to _router-1_:
  ```bash
    ip route add 192.168.0.0/8 via 192.168.10.254
  ```


#### Host B

Here the code used in the Vagrantfile to create the VM with one interface. Then it will execute the provisioning script "host-1-b.sh".
  ```ruby
    config.vm.define "host-1-b" do |hostb|
      hostb.vm.box = "minimal/trusty64"
      hostb.vm.hostname = "host-1-b"
      hostb.vm.network "private_network", virtualbox__intnet: "broadcast_host_b", auto_config: false
      hostb.vm.provision "shell", path: "host-1-b.sh"
    end
  ```
##### Provisioning script


IP address configuration on _eth1_ and interface set up:
  ```bash
    ip addr add 192.168.20.1/27 dev eth1
    ip link set eth1 up
  ```
Set a static route to _router-1_:
  ```bash
    ip route add 192.168.0.0/8 via 192.168.20.30
  ```

#### Host C

Here the code used in the Vagrantfile to create the VM with one interface. Then it will execute the provisioning script "host-2-c.sh".
  ```ruby
    config.vm.define "host-2-c" do |hostc|
      hostc.vm.box = "minimal/trusty64"
      hostc.vm.hostname = "host-2-c"
      hostc.vm.network "private_network", virtualbox__intnet: "broadcast_router-south-2", auto_config: false
      hostc.vm.provision "shell", path: "host-2-c.sh"
    end
  ```
##### Provisioning script

IP address configuration on _eth1_ and interface set up:
  ```bash
    ip addr add 192.168.30.1/30 dev eth1
    ip link set eth1 up
  ```
Set a static route to _router-2_:
  ```bash
    ip route add 192.168.0.0/8 via 192.168.30.2
  ```
Docker configuration to create a webserver based on Nginx and a webpage located in _/docker-nginx/html_ directory.

  ```bash
    docker pull nginx
    mkdir -p ~/docker-nginx/html
    echo "<html>
    <head><title>DNCS ASSIGNMENT</title></head>
    <body>
    <p>Host C website.<p>
    </body>
    </html>" > ~/docker-nginx/html/index.html
    docker run --name docker-nginx -p 80:80 -d -v ~/docker-nginx/html:/usr/share/nginx/html nginx
  ```
  Note: due to compatibility issues with Trusty64, the docker version installed is 18.06.1
    ```bash
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce=18.06.1~ce~3-0~ubuntu jq --assume-yes --force-yes
    ```

## How-to test

-   Install Virtualbox and Vagrant
-   Open the terminal and execute the command: `git clone https://github.com/gvlaan/dncs-lab`
-   You should be able to launch the lab from within the cloned repo folder.
  ```
    cd dncs-lab
    [~/dncs-lab] vagrant up --provision
  ```

Once you launch the vagrant script, it may take a while for the entire topology to become available.

-   Verify the status of the 6 VMs
  ```
    [dncs-lab]$ vagrant status  
    Current machine states:
    router-1                  running (virtualbox)
    router-2                  running (virtualbox)
    switch                    running (virtualbox)
    host-1-a                  running (virtualbox)
    host-1-b                  running (virtualbox)
    host-2-c                  running (virtualbox)
  ```
-   Once all the VMs are running verify you can log into all of them:
  ```
    vagrant ssh router-1
    vagrant ssh router-2
    vagrant ssh switch
    vagrant ssh host-1-a
    vagrant ssh host-1-b
    vagrant ssh host-2-c
  ```
  To log out use the command `exit`

-   To test reachability log into `host-2-c` and try to ping `host-1-b` with `ping 192.168.20.1`

  ```bash
    [dncs-lab]$ vagrant ssh host-2-c
    vagrant@host-2-c: ping 192.168.20.1
  ```
and vice versa:
  ```bash
    [dncs-lab]$ vagrant ssh host-1-b
    vagrant@host-1-b: ping 192.168.30.1
  ```
-   Get the webpage from `host-2-c` with `curl 192.168.30.1`
  ```bash
    vagrant@host-1-b: curl 192.168.30.1
  ```
