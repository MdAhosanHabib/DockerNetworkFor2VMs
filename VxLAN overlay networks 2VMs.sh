########
Step 1:#
########
-----host 1: create network for docker
[root@ahosan1 ~]# docker network create --subnet 172.18.0.0/16 vxlan-net
3bde46980302fdcf5dc0d8dc170d5a2fc4c6a6f202a05a2f7844bf831e5552df
[root@ahosan1 ~]#

[root@ahosan1 ~]# docker network ls
NETWORK ID     NAME        DRIVER    SCOPE
4b24b083e280   bridge      bridge    local
89aae8bf0d87   host        host      local
58e20f7d3343   none        null      local
3bde46980302   vxlan-net   bridge    local
[root@ahosan1 ~]#

-----host 2: create network for docker
[root@ahosan2 ~]# docker network create --subnet 172.18.0.0/16 vxlan-net
521e8fb4acf1ab52d5a12602c836a93a554ef6cee3b1ca540219a7e436b66574
[root@ahosan2 ~]#

[root@ahosan2 ~]# docker network ls
NETWORK ID     NAME        DRIVER    SCOPE
db58c1279bee   bridge      bridge    local
a98ebe986154   host        host      local
e40959afaac6   none        null      local
521e8fb4acf1   vxlan-net   bridge    local
[root@ahosan2 ~]#


########
Step 2:#
########
-----host 1: run docker container on the created network
[root@ahosan1 ~]# docker run -d --net vxlan-net --ip 172.18.0.11 ubuntu sleep 3000
Unable to find image 'ubuntu:latest' locally
latest: Pulling from library/ubuntu
3153aa388d02: Pull complete
Digest: sha256:0bced47fffa3361afa981854fcabcd4577cd43cebbb808cea2b1f33a3dd7f508
Status: Downloaded newer image for ubuntu:latest
6e5e3a2bd5271e9addb2e490f266f695f80c86942083ab882c96da0efcae3e63
[root@ahosan1 ~]#

[root@ahosan1 ~]# docker ps
CONTAINER ID   IMAGE     COMMAND        CREATED         STATUS         PORTS     NAMES
6e5e3a2bd527   ubuntu    "sleep 3000"   4 minutes ago   Up 4 minutes             peaceful_yonath
[root@ahosan1 ~]#

[root@ahosan1 ~]# docker inspect 6e5e3a2bd527 | grep IPAddress
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "172.18.0.11",
[root@ahosan1 ~]#

[root@ahosan1 ~]# ping 172.18.0.1 -c 2
PING 172.18.0.1 (172.18.0.1) 56(84) bytes of data.
64 bytes from 172.18.0.1: icmp_seq=1 ttl=64 time=0.041 ms
64 bytes from 172.18.0.1: icmp_seq=2 ttl=64 time=0.047 ms
--- 172.18.0.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 16ms
rtt min/avg/max/mdev = 0.041/0.044/0.047/0.003 ms
[root@ahosan1 ~]#

-----host 2: run docker container on the created network
[root@ahosan2 ~]# docker run -d --net vxlan-net --ip 172.18.0.12 ubuntu sleep 3000
Unable to find image 'ubuntu:latest' locally
latest: Pulling from library/ubuntu
3153aa388d02: Pull complete
Digest: sha256:0bced47fffa3361afa981854fcabcd4577cd43cebbb808cea2b1f33a3dd7f508
Status: Downloaded newer image for ubuntu:latest
f514ea38604b3f32a79f1a844809e1cde4d959259c51dd2dd46dec6bc6c31ead

[root@ahosan2 ~]# docker ps
CONTAINER ID   IMAGE     COMMAND        CREATED         STATUS         PORTS     NAMES
f514ea38604b   ubuntu    "sleep 3000"   4 minutes ago   Up 4 minutes             sleepy_wescoff
[root@ahosan2 ~]#

[root@ahosan2 ~]# docker inspect f514ea38604b | grep IPAddress
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "172.18.0.12",
[root@ahosan2 ~]#

[root@ahosan2 ~]# ping 172.18.0.1 -c 2
PING 172.18.0.1 (172.18.0.1) 56(84) bytes of data.
64 bytes from 172.18.0.1: icmp_seq=1 ttl=64 time=0.044 ms
64 bytes from 172.18.0.1: icmp_seq=2 ttl=64 time=0.047 ms
--- 172.18.0.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 13ms
rtt min/avg/max/mdev = 0.044/0.045/0.047/0.006 ms
[root@ahosan2 ~]#


########
Step 3:#
########
-----host 1: install needed package
docker exec -it 6e5e3a2bd527 bash
#update the package in CONTAINER
apt-get update
apt-get install net-tools
apt-get install iputils-ping
ping 172.18.0.12 -c 2

-----host 2: install needed package
docker exec -it f514ea38604b bash
#update the package in CONTAINER
apt-get update
apt-get install net-tools
apt-get install iputils-ping
ping 172.18.0.11 -c 2


########
Step 4:#
########
-----host 1: create vxlan and added to bridge with Destination host
root@6e5e3a2bd527:/# exit
[root@ahosan1 ~]# pwd
/root
[root@ahosan1 ~]# rpm -ivh bridge-utils-1.5-9.el7.x86_64.rpm
warning: bridge-utils-1.5-9.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
Verifying...                          ################################# [100%]
Preparing...                          ################################# [100%]
Updating / installing...
   1:bridge-utils-1.5-9.el7           ################################# [100%]
[root@ahosan1 ~]#

[root@ahosan1 ~]# brctl show
bridge name     bridge id               STP enabled     interfaces
br-3bde46980302         8000.0242713d4b99       no              veth751c272
docker0         8000.024246e94e90       no
virbr0          8000.52540004ef68       yes             virbr0-nic
virbr1          8000.525400b25e18       yes             virbr1-nic
[root@ahosan1 ~]#

[root@ahosan1 ~]# ip link add vxlan-demo type vxlan id 100 remote 192.168.222.129 dstport 4789 dev ens160
[root@ahosan1 ~]# ip a | grep vxlan
11: vxlan-demo: <BROADCAST,MULTICAST> mtu 1450 qdisc noop state DOWN group default qlen 1000
[root@ahosan1 ~]#
[root@ahosan1 ~]# ip link set vxlan-demo up
[root@ahosan1 ~]#
[root@ahosan1 ~]# brctl addif br-3bde46980302 vxlan-demo

[root@ahosan1 ~]# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.222.2   0.0.0.0         UG    100    0        0 ens160
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
172.18.0.0      0.0.0.0         255.255.0.0     U     0      0        0 br-3bde46980302
192.168.39.0    0.0.0.0         255.255.255.0   U     0      0        0 virbr1
192.168.122.0   0.0.0.0         255.255.255.0   U     0      0        0 virbr0
192.168.222.0   0.0.0.0         255.255.255.0   U     100    0        0 ens160
[root@ahosan1 ~]#

-----host 2: create vxlan and added to bridge with Destination host
root@f514ea38604b:/# exit
[root@ahosan2 ~]# yum install bridge-utils
Last metadata expiration check: 0:11:06 ago on Sun 16 Jul 2023 07:18:36 PM +06.
No match for argument: bridge-utils
Error: Unable to find a match: bridge-utils
[root@ahosan2 ~]# rpm -ivh bridge-utils-1.5-9.el7.x86_64.rpm
warning: bridge-utils-1.5-9.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
Verifying...                          ################################# [100%]
Preparing...                          ################################# [100%]
Updating / installing...
   1:bridge-utils-1.5-9.el7           ################################# [100%]
[root@ahosan2 ~]#

[root@ahosan2 ~]# brctl show
bridge name     bridge id               STP enabled     interfaces
br-521e8fb4acf1         8000.02420eaeaa56       no              veth810dfd6
docker0         8000.024264307cd2       no
virbr0          8000.525400eb2a2a       yes             virbr0-nic
[root@ahosan2 ~]#
[root@ahosan2 ~]# ip link add vxlan-demo type vxlan id 100 remote 192.168.222.128 dstport 4789 dev ens160
[root@ahosan2 ~]#
[root@ahosan2 ~]# ip a | grep vxlan
9: vxlan-demo: <BROADCAST,MULTICAST> mtu 1450 qdisc noop state DOWN group default qlen 1000
[root@ahosan2 ~]#
[root@ahosan2 ~]# ip link set vxlan-demo up
[root@ahosan2 ~]#
[root@ahosan2 ~]# brctl addif br-521e8fb4acf1 vxlan-demo
[root@ahosan2 ~]#
[root@ahosan2 ~]# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.222.2   0.0.0.0         UG    100    0        0 ens160
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
172.18.0.0      0.0.0.0         255.255.0.0     U     0      0        0 br-521e8fb4acf1
192.168.122.0   0.0.0.0         255.255.255.0   U     0      0        0 virbr0
192.168.222.0   0.0.0.0         255.255.255.0   U     100    0        0 ens160
[root@ahosan2 ~]#


########
Step 5:#
########
-----host 1: check connection
[root@ahosan1 ~]# docker exec -it 6e5e3a2bd527 bash
root@6e5e3a2bd527:/# ping 172.18.0.12 -c 2
PING 172.18.0.12 (172.18.0.12) 56(84) bytes of data.
64 bytes from 172.18.0.12: icmp_seq=1 ttl=64 time=0.555 ms
64 bytes from 172.18.0.12: icmp_seq=2 ttl=64 time=0.574 ms
--- 172.18.0.12 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1006ms
rtt min/avg/max/mdev = 0.555/0.564/0.574/0.009 ms
root@6e5e3a2bd527:/#

-----host 2: check connection
[root@ahosan2 ~]# docker exec -it f514ea38604b bash
root@f514ea38604b:/# ping 172.18.0.11 -c 2
PING 172.18.0.11 (172.18.0.11) 56(84) bytes of data.
64 bytes from 172.18.0.11: icmp_seq=1 ttl=64 time=0.493 ms
64 bytes from 172.18.0.11: icmp_seq=2 ttl=64 time=0.533 ms
--- 172.18.0.11 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1027ms
rtt min/avg/max/mdev = 0.493/0.513/0.533/0.020 ms
root@f514ea38604b:/#

Congratulations.
