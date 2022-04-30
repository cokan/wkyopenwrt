#! /bin/bash
echo "\e[32m ================ 1: 更新系统 ================ \e[0m"
cp /etc/apt/sources.list /etc/apt/sources.list.bak
apt update
apt upgrade -y

echo "\e[32m ================ 2: 更换hosts ================ \e[0m"
# github mirror updating script written by chuixue
# mirror source from: https://github.com/521xueweihan/GitHub520

# get the new hosts from the internet. You can change the source if you have a better one.
curl 'https://raw.hellogithub.com/hosts' > github_hosts.log

# remove the lines between "github hosts start" and "github hosts end" in /etc/hosts
echo "$(sed '/# github hosts start; Do not remove or change this line/,/# github hosts end; Do not remove or change this line/d' /etc/hosts)" > /etc/hosts

# add the start and end lines
sh -c 'echo "# github hosts start; Do not remove or change this line
# github hosts end; Do not remove or change this line" >> /etc/hosts'

# insert the new hosts into /etc/hosts
echo "$(sed '/# github hosts start; Do not remove or change this line/r github_hosts.log' /etc/hosts)" > /etc/hosts

echo "\e[32m ================ 3: 添加pip源 ================ \e[0m"

cat << EOF | sudo tee /etc/pip.conf
[global]
timeout = 10
index-url = http://mirrors.aliyun.com/pypi/simple/ 
index-index-url = http://pypi.douban.com/simple/
[install]
trusted-host =
　　mirrors.aliyun.com
　　pypi.douban.com
EOF

echo "\e[32m ================ 4: 安装docker ================ \e[0m"
# 1.安装docker
curl -sSL https://get.daocloud.io/docker | sh
# 2.安装加速
if [ ! -d /etc/docker ];then
   sudo mkdir -p /etc/docker
fi
cat << EOF | sudo tee /etc/docker/daemon.json 
{ 
    "log-driver": "journald",
    "registry-mirrors": [ 
    "https://rw21enj1.mirror.aliyuncs.com",
    "https://dockerhub.azk8s.cn",
    "https://reg-mirror.qiniu.com",
    "https://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn"
    ]
}
EOF
# 3.安装docker-compose
sudo curl -fsSL https://raw.githubusercontent.com/aleksanderlech/armv7-docker-compose/master/run.sh -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

echo "\e[32m ================ 5: 安装镜像 ================ \e[0m"
docker pull dickhub/openwrt:armv7
ip link set eth0 promisc on
docker network create -d macvlan --subnet=192.168.0.0/24 --gateway=192.168.0.1 -o parent=eth0 macnet
docker run -i -t -d --name=openwrt --restart=always --network=macnet --privileged=true dickhub/openwrt:armv7 /sbin/init
docker exec -it openwrt bash

echo "\e[32m ================ 6: 执行更新，修复依赖 ================ \e[0m"
sudo apt-get update
sudo apt-get -f install -y
