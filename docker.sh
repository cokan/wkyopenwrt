#!/bin/sh -e
#一键安装命令:
#bash <(curl -L -s https://sumju.net/docker.sh)
#另一种一键安装命令:
#source <(curl -s https://sumju.net/docker.sh)
#树莓派镜像下载地址:
#OneDrive : https://1drv.ms/u/s!AnVTrriZ2E3uawzra4DdPnln9c4?e=yNbfRD
#百度盘链接：https://pan.baidu.com/s/1UVwEQG5aVgM49VhhmYNaww  提取码：17z8
#YaDisk 下载地址：https://yadi.sk/d/WGFjXqa9xrFPPg
#斐讯N1镜像下载地址:
#YaDisk 下载地址：https://yadi.sk/d/4Luurr99c90MfA

echo "----------------------------------------------------------------------"
for i in $(seq -w 10 -1 0); do
  echo -en "||安装将会在\e[0;31m$i\e[0m秒内开始!此版本为\e[0;31m2020年5月29日\e[0m版本！||\r"
  sleep 1
done

#斐讯N1更换apt源
if [ -e "/boot/uEnv.txt" ]; then
  #apt-get update
  #apt-get install -y dhcpcd5 cockpit php7*-fpm
  #apt install -y mariadb-client-core-10.1 libncurses5 libreadline5 libtinfo5 --allow-remove-essential

  if [ -e "/root/install.sh" ]; then
    sed -i '/docker/d' /root/install.sh
    sed -i "2isystemctl stop docker" /root/install.sh
  fi

fi

runpath=$(pwd)

#矫正系统时间
sudo apt-get install -y ntpdate
sudo ntpdate ntp.sjtu.edu.cn
sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#开启树莓派声卡
if [ -e "/boot/config.txt" ]; then
  sudo sh -c "sed -i '106s/#\ //' /boot/config.txt"
  sudo apt-get install -y alsa-utils
fi

#更新和安装所需软件
#sudo sh -c "dpkg --configure -a"
sudo apt-get update
#sudo apt-get upgrade -y
sudo apt-get install -y fail2ban zip git make gcc cockpit python3.7 avahi-daemon etherwake nmap ntfs-3g openssl php7*-fpm dsniff traceroute sudo
sudo apt-get install -y mariadb-client
sudo systemctl enable fail2ban
sudo systemctl enable avahi-daemon
sudo sh -c "sed -i '/ipv6/d' /etc/avahi/avahi-daemon.conf"
sudo systemctl restart avahi-daemon
sudo systemctl enable cockpit
sudo apt-get clean

#删除cockpit错误显示
sudo sh -c "rm -rf /etc/motd.d/cockpit"

#修改php.ini 时区为RPC
sudo sh -c "sed -i 's/;\ date.timezone\ =/\ date.timezone\ \=\ RPC/' /etc/php/7.3/cli/php.ini"
sudo sh -c "sed -i 's/;\ date.timezone\ =/\ date.timezone\ \=\ RPC/' /etc/php/7.3/fpm/php.ini"
sudo sh -c "sed -i 's/;date.timezone\ =/\ date.timezone\ \=\ RPC/' /etc/php/7.3/cli/php.ini"
sudo sh -c "sed -i 's/;date.timezone\ =/\ date.timezone\ \=\ RPC/' /etc/php/7.3/fpm/php.ini"

#让宿主机可以访问MySQL
if [ -e "/boot/uEnv.txt" ]; then
  sudo sh -c "sed -i 's/\/var\/run\/mysqld\/mysqld\.sock/\/opt\/mysql\/mysqld\.sock/' /etc/mysql/mariadb.conf.d/50-client.cnf"
  #sed -i '/mysql/d' /etc/mysql/conf.d/mysql.cnf
  echo "[mysql]" >/etc/mysql/conf.d/mysql.cnf
  echo "[client]" >>/etc/mysql/conf.d/mysql.cnf
  echo "socket = /opt/mysql/mysqld.sock  " >>/etc/mysql/conf.d/mysql.cnf
else
  sudo sh -c "sed -i 's/\/var\/run\/mysqld\/mysqld.sock/\/opt\/mysql\/mysqld.sock/' /etc/mysql/mariadb.conf.d/50-client.cnf"
fi

#开启bbr加速，和内核转发net.ipv6.conf.all.forwarding=1
#/etc/sysctl.conf
sudo sh -c "sed -i '/net.ipv4.ip_forward\ =\ 1/d' /etc/sysctl.conf"
sudo sh -c "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf"
sudo sh -c "sed -i '/net.ipv6.conf.all.forwarding/d' /etc/sysctl.conf"
sudo sh -c "echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf"
sudo sh -c "sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf"
sudo sh -c "echo 'net.core.default_qdisc = fq' >> /etc/sysctl.conf"
sudo sh -c "sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf"
sudo sh -c "echo 'net.ipv4.tcp_congestion_control = bbr' >> /etc/sysctl.conf"
sudo sysctl -p

#新增开机启动项
#/etc/rc.local
sudo sh -c "sed -i '/exit\ 0/d' /etc/rc.local"
sudo sh -c "sed -i '/sleep\ 5/d' /etc/rc.local"

#音量开到100%并保存
sudo sh -c "sudo sed -i '/amixer/d' /etc/rc.local"
sudo sh -c "sudo sed -i '/alsactl/d' /etc/rc.local"
if [ ! -e "/boot/uEnv.txt" ]; then
  sudo sh -c "echo 'amixer sset 'PCM' 100%' >> /etc/rc.local"
  sudo sh -c "echo 'alsactl store' >> /etc/rc.local"
fi
if [ -e "/boot/uEnv.txt" ]; then
  sudo sh -c "sudo sed -i '/pulseaudio/d' /etc/rc.local"
  sudo sh -c "echo 'pulseaudio --system --disallow-exit --disallow-module-loading &' >> /etc/rc.local"
fi
sudo sh -c "echo 'sudo sed -i '/amixer/d' /etc/rc.local' >> /etc/rc.local"
sudo sh -c "echo 'sudo sed -i '/alsactl/d' /etc/rc.local' >> /etc/rc.local"

#开机网口混杂模式和pppoe模块
sudo sh -c "sed -i '/ip/d' /etc/rc.local"
sudo sh -c "sed -i '/\<fi\>/d' /etc/rc.local"
sudo sh -c "sed -i '/gw/d' /etc/rc.local"
sudo sh -c "sed -i '/ifconfig\ eth0\ promisc/d' /etc/rc.local"
sudo sh -c "echo 'ifconfig eth0 promisc' >> /etc/rc.local"
sudo sh -c "sed -i '/modprobe\ pppoe/d' /etc/rc.local"
sudo sh -c "echo 'modprobe pppoe' >> /etc/rc.local"

#运行openwrt宿主机访问脚本
sudo sh -c "sed -i '/openwrt/d' /etc/rc.local"
sudo sh -c "sed -i '/arpspoof/d' /etc/rc.local"
sudo sh -c "echo '
/bin/bash /opt/openwrt < /dev/null 2>&1 &
' >> /etc/rc.local"

sudo sh -c "echo 'exit 0' >> /etc/rc.local"

#桥接OpenWRT可以让宿主机访问
sudo sh -c 'echo "#!/bin/bash" > /opt/openwrt'
sudo sh -c "echo '
if [ \"\$(cat /sys/class/net/eth0/carrier)\" == \"0\" ]; then
exit 0
fi
sleep 90
ip=\$(sudo ifconfig eth0 | grep \"inet \" | awk '\'\{print \$\2}\'')
ip1=\$(echo \$ip | awk -F '\'.\'' '\'\{print \$\1}\'')
ip2=\$(echo \$ip | awk -F '\'.\'' '\'\{print \$\2}\'')
ip3=\$(echo \$ip | awk -F '\'.\'' '\'\{print \$\3}\'')
subnet=\$(sudo ip -4 address|grep inet| grep eth0 | awk '\'{print \$\2}\'' | awk -F \"/\" '\'\{print \$\2}\'')
subnet=\$(echo \$subnet | awk '\'\{print \$\1}\'')
if [ \"\$subnet\" == \"16\" ]; then
ip3=\"0\"
fi
ip1=\$(echo \$ip1.\$ip2.\$ip3.0/\$subnet)
ip1=\$(echo \$ip1 | awk '\'\{print \$\1}\'')

if [ \"\$ip\" != \"\" ]; then
  sudo ip link add macvlan link eth0 type macvlan mode bridge
  sudo ip link set macvlan up
  if [ \`command -v docker\` ];then
    if [ \"\$(docker ps -q -a -f name=OpenWRT)\" ]; then
      gw=\$(docker exec -i OpenWRT ip -4 address|grep inet| grep /32 | awk '\'{print \$\2}\'' | awk -F \"/\" '\'{print \$\1}\'')
      sudo ip route add \$ip1 dev macvlan
      sudo ip route add default via \$gw dev macvlan
      sudo sed -i '\'/openwrt/d\'' /etc/avahi/hosts
      sudo sh -c \"echo '\'\$\gw openwrt.local\'' >> /etc/avahi/hosts\"
      sudo systemctl restart avahi-daemon
      gw=\$(sudo route -n | grep eth0 | grep UG | awk '\'{print \$\2}\'')
      gw=\$(echo \$gw | awk '\'{print \$\1}\'')
      docker exec -i OpenWRT sed -i '/$\gw/d' /etc/config/shadowsocksr
      docker exec -i OpenWRT sed -i '\'/109.239.140.0/a'\'list lan_ac_ips \'$\gw\'\'' /etc/config/shadowsocksr
      docker exec -i OpenWRT /etc/init.d/shadowsocksr restart
      #arpspoof -i eth0 -c own \$gw > /dev/null 2>&1 &
      sleep 1
      #arpspoof -i eth0 -c own \$gw > /dev/null 2>&1 &
      sleep 1
      #arpspoof -i eth0 -c own \$gw > /dev/null 2>&1 &
    else
      gw=\$(sudo route -n | grep eth0 | grep UG | awk '\'{print \$\2}\'')
      gw=\$(echo \$gw | awk '\'{print \$\1}\'')
      sudo sed -i '\'/openwrt/d\'' /etc/avahi/hosts
      sudo systemctl restart avahi-daemon
      sudo ip route add \$ip1 dev macvlan
      sudo ip route add default via \$gw dev macvlan
    fi
  fi
fi
' >> /opt/openwrt"

sudo sh -c "sed -i '/macvlan/d' /etc/dhcpcd.conf"
sudo sh -c "echo 'denyinterfaces macvlan' >> /etc/dhcpcd.conf"

sudo chmod +x /opt/openwrt

#斐讯N1安装蓝牙驱动
if [ -e "/boot/uEnv.txt" ]; then
  cd /lib/firmware/brcm/
  sudo sh -c " rm -rf BCM4345C0.hcd"
  #wget https://raw.githubusercontent.com/RPi-Distro/bluez-firmware/master/broadcom/BCM4345C0.hcd
  wget https://sumju.net/BCM4345C0.hcd
  sudo chmod +x BCM4345C0.hcd
  sudo rm -rf /opt/resource/iobroker.zip
  sudo rm -rf /opt/resource/node-red.zip
  sudo apt-get -y install pulseaudio pulseaudio-module-bluetooth
fi
sudo apt-get -y install bluez

#安装Docker运行环境
# install docker

if [ ! $(command -v docker) ]; then
  if [ -e "/opt/resource/containerd.io_1.2.6-3_arm64.deb" ]; then
    sudo sh -c "dpkg -i /opt/resource/*.deb"
  else
    sudo curl -sSL https://get.docker.com/ -k | sh
  fi
fi
sudo sh -c "rm -rf /opt/resource/*.deb"
sudo sh -c "sudo systemctl enable docker"
sudo sh -c "sudo systemctl start docker"

#新建配置文件目录并赋予权限
sudo mkdir -p /opt/hass
sudo mkdir -p /opt/hass/custom_components
sudo mkdir -p /opt/hass/.storage
sudo chmod -R 777 /opt/hass
sudo mkdir -p /opt/zigbee2mqtt
sudo chmod -R 777 /opt/zigbee2mqtt
sudo mkdir -p /opt/mopidy
sudo chmod -R 777 /opt/mopidy
sudo mkdir -p /opt/mosquitto
sudo chmod -R 777 /opt/mosquitto
sudo mkdir -p /opt/mosquitto/data
sudo mkdir -p /opt/mosquitto/log
sudo mkdir -p /opt/esphome
sudo chmod -R 777 /opt/esphome
sudo mkdir -p /opt/homebridge
sudo chmod -R 777 /opt/homebridge
sudo mkdir -p /opt/motioneye
sudo chmod -R 777 /opt/motioneye
sudo mkdir -p /opt/motioneye/etc
sudo mkdir -p /opt/motioneye/lib
sudo mkdir -p /opt/mysql
sudo chmod -R 777 /opt/mysql
sudo mkdir -p /opt/mysql/lib
if [ ! -e "/boot/uEnv.txt" ]; then
  sudo mkdir -p /opt/iobroker
  sudo chmod -R 777 /opt/iobroker
  sudo mkdir -p /opt/node-red
  sudo chmod -R 777 /opt/node-red
fi

#安装Docker Portainer容器管理工具
sudo mkdir -p /opt/portainer
sudo mkdir -p /opt/portainer/data
sudo mkdir -p /opt/portainer/certs
sudo mkdir -p /opt/portainer/public

#汉化Portainer
cd /opt/portainer/public
sudo rm -rf *
sudo wget https://sumju.net/Portainer-CN.zip
if [ ! -e "/opt/portainer/public/Portainer-CN.zip" ]; then
  sudo wget https://sumju.net/Portainer-CN.zip
fi
sudo sh -c "unzip -o  Portainer-CN.zip"
sudo sh -c "rm -rf *.zip"
sudo chmod -R 777 /opt/portainer

# self sign certifacate
if [ ! -e "/opt/portainer/certs/portainer.crt" ]; then
  cd /opt/portainer/certs
  sudo openssl req -subj '/CN=itcommander.local/O=sumju.net/C=CN' -new -newkey rsa:2048 -days 18250 -nodes -x509 -keyout /opt/portainer/certs/portainer.key -out /opt/portainer/certs/portainer.crt
  sudo cp -f /opt/portainer/certs/portainer.crt /etc/cockpit/ws-certs.d/0-self-signed.cert
  sudo sh -c "cat /opt/portainer/certs/portainer.key >> /etc/cockpit/ws-certs.d/0-self-signed.cert"
  sudo systemctl restart cockpit
fi

#导入各种镜像
if [ -e "/opt/resource/portainer.zip" ]; then
  sudo sh -c "unzip -o  /opt/resource/portainer.zip -d /opt/resource/"
  sudo sh -c "docker load < /opt/resource/portainer.tar"
  sudo sh -c "rm -rf /opt/resource/portainer.*"
fi

if [ -e "/opt/resource/homeassistant.zip" ]; then
  sudo sh -c "unzip -o  /opt/resource/homeassistant.zip -d /opt/resource/"
  sudo sh -c "docker load < /opt/resource/homeassistant.tar"
  sudo sh -c "rm -rf /opt/resource/homeassistant.*"
fi

if [ ! -e "/boot/uEnv.txt" ]; then

  if [ -e "/opt/resource/iobroker.zip" ]; then
    sudo sh -c "unzip -o  /opt/resource/iobroker.zip -d /opt/resource/"
    sudo sh -c "docker load < /opt/resource/iobroker.tar"
    sudo sh -c "rm -rf /opt/resource/iobroker.*"
  fi

  if [ -e "/opt/resource/node-red.zip" ]; then
    sudo sh -c "unzip -o  /opt/resource/node-red.zip -d /opt/resource/"
    sudo sh -c "docker load < /opt/resource/node-red.tar"
    sudo sh -c "rm -rf /opt/resource/node-red.*"
  fi

  if [ -e "/opt/resource/esphome.zip" ]; then
    sudo sh -c "unzip -o /opt/resource/esphome.zip -d /opt/resource/"
    sudo sh -c "docker load < /opt/resource/esphome.tar"
    sudo sh -c "rm -rf /opt/resource/esphome.*"
  fi

fi

if [ -e "/opt/resource/mopidy.zip" ]; then
  sudo sh -c "unzip -o /opt/resource/mopidy.zip -d /opt/resource/"
  sudo sh -c "docker load < /opt/resource/mopidy.tar"
  sudo sh -c "rm -rf /opt/resource/mopidy.*"
fi

if [ -e "/opt/resource/mosquitto.zip" ]; then
  sudo sh -c "unzip -o /opt/resource/mosquitto.zip -d /opt/resource/"
  sudo sh -c "docker load < /opt/resource/mosquitto.tar"
  sudo sh -c "rm -rf /opt/resource/mosquitto.*"
fi

if [ -e "/opt/resource/homebridge.zip" ]; then
  sudo sh -c "unzip -o /opt/resource/homebridge.zip -d /opt/resource/"
  sudo sh -c "docker load < /opt/resource/homebridge.tar"
  sudo sh -c "rm -rf /opt/resource/homebridge.*"
fi

if [ -e "/opt/resource/mariadb.zip" ]; then
  sudo sh -c "unzip -o /opt/resource/mariadb.zip -d /opt/resource/"
  sudo sh -c "docker load < /opt/resource/mariadb.tar"
  sudo sh -c "rm -rf /opt/resource/mariadb.*"
fi

if [ -e "/opt/resource/zigbee2mqtt.zip" ]; then
  sudo sh -c "unzip -o /opt/resource/zigbee2mqtt.zip -d /opt/resource/"
  sudo sh -c "docker load < /opt/resource/zigbee2mqtt.tar"
  sudo sh -c "rm -rf /opt/resource/zigbee2mqtt.*"
fi

if [ -e "/opt/resource/configurator.zip" ]; then
  sudo sh -c "unzip -o /opt/resource/configurator.zip -d /opt/resource/"
  sudo sh -c "docker load < /opt/resource/configurator.tar"
  sudo sh -c "rm -rf /opt/resource/configurator.*"
fi

if [ -e "/opt/resource/motioneye.zip" ]; then
  sudo sh -c "unzip -o /opt/resource/motioneye.zip -d /opt/resource/"
  sudo sh -c "docker load < /opt/resource/motioneye.tar"
  sudo sh -c "rm -rf /opt/resource/motioneye.*"
fi

if [ -e "/opt/resource/openwrt.zip" ]; then
  sudo sh -c "unzip -o /opt/resource/openwrt.zip -d /opt/resource/"
  sudo sh -c "docker load < /opt/resource/openwrt.tar"
  sudo sh -c "rm -rf /opt/resource/openwrt.*"
fi

if [ ! "$(docker ps -q -a -f name=Portainer)" ]; then
  docker run -d -p 8443:9000 -p :8000 --restart=unless-stopped \
    --name Portainer -e TZ=Asia/Shanghai \
    --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /opt/portainer/certs:/certs \
    -v /opt/portainer/data:/data \
    -v /opt/portainer/public:/public \
    portainer/portainer \
    --ssl --sslcert /certs/portainer.crt --sslkey /certs/portainer.key
fi

#建立OpenWRT容器和网卡
if [ "$(cat /sys/class/net/eth0/carrier)" == "1" ]; then

  ip=$(sudo ifconfig eth0 | grep "inet " | awk '{print $2}')
  ip1=$(echo $ip | awk -F '.' '{print $1}')
  ip2=$(echo $ip | awk -F '.' '{print $2}')
  ip3=$(echo $ip | awk -F '.' '{print $3}')
  subnet=$(sudo ip -4 address | grep inet | grep eth0 | awk '{print $2}' | awk -F "/" '{print $2}')
  subnet=$(echo $subnet | awk '{print $1}')
  if [ "$subnet" == "16" ]; then
    ip3="0"
  fi
  ip1=$(echo $ip1.$ip2.$ip3.0/$subnet)
  ip1=$(echo $ip1 | awk '{print $1}')
  gw=$(sudo route -n | grep eth0 | grep UG | awk '{print $2}')
  gw=$(echo $gw | awk '{print $1}')

  if [ ! "$(docker network ls -f name=macnet -q)" ]; then
    docker network create -d macvlan \
      --subnet=$ip1 --gateway=$gw \
      --ipv6 --subnet=fe80::/16 --gateway=fe80::1 \
      -o parent=eth0 \
      -o macvlan_mode=bridge \
      macnet
  fi

  if [ ! "$(docker ps -q -a -f name=OpenWRT)" ]; then
    docker run -d --name="OpenWRT" \
      --restart unless-stopped \
      --network macnet \
      --privileged \
      kanshudj/n1-openwrtgateway:r9.10.1 \
      /sbin/init
  fi
else
  echo "----------------------------------------------------------------------"
  for i in $(seq -w 10 -1 0); do
    echo -en "||未检测到网线插入,OpenWrt跳过安装，\e[0;31m$i\e[0m秒内开始后续安装！||\r"
    sleep 1
  done
fi

# 启动所需各种容器
if [ ! "$(docker ps -q -a -f name=Home-Assistant)" ]; then
  docker run -d \
    --name="Home-Assistant" \
    --restart unless-stopped \
    -v /opt/hass:/config \
    --privileged \
    --hostname="itcommander" \
    -e TZ=Asia/Shanghai \
    --net=host \
    homeassistant/home-assistant
fi

if [ ! "$(docker ps -q -a -f name=MQTT)" ]; then
  docker run -d \
    --name="MQTT" \
    --restart unless-stopped \
    -e TZ=Asia/Shanghai \
    -v /opt/mosquitto/data:/mosquitto/data \
    -v /opt/mosquitto/log:/mosquitto/log \
    --hostname="itcommander" \
    --net=host \
    arm64v8/eclipse-mosquitto:latest
fi

if [ ! -e "/boot/uEnv.txt" ]; then

  if [ ! "$(docker ps -q -a -f name=Node-Red)" ]; then
    docker run -d \
      --name="Node-Red" \
      --restart unless-stopped \
      -v /opt/node-red:/data \
      -e TZ=Asia/Shanghai \
      --hostname="itcommander" \
      --net=host \
      nodered/node-red
  fi

  if [ ! "$(docker ps -q -a -f name=IOBroker)" ]; then
    docker run -d \
      --name "IOBroker" \
      --restart unless-stopped \
      --hostname="itcommander" \
      -p 8181:8081 \
      -e TZ=Asia/Shanghai \
      -v /opt/iobroker:/iobroker \
      buanet/iobroker:latest
  fi

  if [ ! "$(docker ps -q -a -f name=ESPHome)" ]; then
    docker run -d \
      --name="ESPHome" \
      -e TZ=Asia/Shanghai \
      --hostname="itcommander" \
      -v /opt/esphome:/config \
      -v /run/udev:/run/udev \
      --privileged \
      --restart unless-stopped \
      --net=host \
      esphome/esphome-armhf
  fi

fi

if [ ! "$(docker ps -q -a -f name=Mopidy)" ]; then
  docker run -d \
    --name "Mopidy" \
    --device /dev/snd \
    -v /opt/mopidy:/media/music \
    -v /tmp:/tmp \
    --restart unless-stopped \
    --hostname="itcommander" \
    --net=host \
    --privileged \
    -e TZ=Asia/Shanghai \
    jorenn92/mopidy:aarch64
fi

if [ ! "$(docker ps -q -a -f name=HomeBridge)" ]; then
  docker run -d \
    --name="HomeBridge" \
    -e TZ=Asia/Shanghai \
    --hostname="itcommander" \
    -v /opt/homebridge:/homebridge \
    --restart unless-stopped \
    --net=host \
    oznu/homebridge:latest
fi

if [ ! "$(docker ps -q -a -f name=MariaDB)" ]; then
  docker run -d \
    --name MariaDB \
    --restart unless-stopped \
    --hostname="itcommander" \
    --net=host \
    --privileged \
    -e MYSQL_ROOT_PASSWORD=itcommander \
    -v /opt/mysql/lib:/var/lib/mysql \
    -v /opt/mysql:/var/run/mysqld \
    mariadb:latest
fi

if [ ! "$(docker ps -q -a -f name=ZigBee2MQTT)" ]; then
  docker run -d \
    --name="ZigBee2MQTT" \
    --restart unless-stopped \
    --hostname="itcommander" \
    -e TZ=Asia/Shanghai \
    -v /opt/zigbee2mqtt/:/app/data \
    -v /run/udev:/run/udev:ro \
    --privileged \
    --net=host \
    koenkk/zigbee2mqtt
fi

if [ ! "$(docker ps -q -a -f name=Configurator)" ]; then
  docker run -d \
    --name="Configurator" \
    -e TZ=Asia/Shanghai \
    --hostname="itcommander" \
    -v /opt/hass:/config \
    --net=host \
    --privileged \
    --restart unless-stopped \
    zurajm/hass-configurator:latest-arm64
fi

if [ ! "$(docker ps -q -a -f name=MotionEye)" ]; then
  docker run -d \
    --name="MotionEye" \
    -e TZ=Asia/Shanghai \
    --hostname="itcommander" \
    -v /opt/motioneye/lib:/var/lib/motioneye \
    -v /opt/motioneye/etc:/etc/motioneye \
    -v /dev/bus/usb:/dev/bus/usb \
    --privileged \
    --restart unless-stopped \
    --net=host \
    wgen/motioneye:arm64
fi

#sudo sh -c 'echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6'

if [ ! "$(docker ps -q -a -f name=Z2M-Assistant)" ]; then
  docker run -d \
    --name="Z2M-Assistant" \
    -p 8880:80 \
    -e ASPNETCORE_SETTINGS__MQTTSERVER=127.0.0.1 \
    -e ASPNETCORE_SETTINGS__MQTTUSERNAME= \
    -e ASPNETCORE_SETTINGS__MQTTPASSWORD= \
    --hostname="itcommander" \
    -e TZ=Asia/Shanghai \
    --restart unless-stopped \
    carldebilly/zigbee2mqttassistant:linux-arm64
fi

#HomeBridge Change MAC
sudo apt-get install -y jq
sudo sh -c "cp /opt/resource/config.json /opt/homebridge/"
MAC=$(sudo cat /sys/class/net/eth0/address)
M1=$(echo ${MAC^^})
config=$(jq '.bridge.username' /opt/homebridge/config.json)
M2=$(echo ${config//\"/})

if [ $M1 != $M2 ]; then
  command="/usr/bin/jq '.bridge.username = \"$M1\"' /opt/homebridge/config.json > /opt/homebridge/config1.json"
  echo $command >/tmp/temp.sh
  sudo sh -c "chmod +x /tmp/temp.sh"
  sudo sh -c "/bin/bash /tmp/temp.sh"
  mv -f /opt/homebridge/config1.json /opt/homebridge/config.json
  sudo rm -rf /tmp/temp.sh
fi

#copy configurator file to HomeAssitant config
sudo sh -c "cp /opt/resource/settings.conf /opt/hass/"
sudo sh -c "cp /opt/resource/configuration.yaml /opt/hass/"
sudo sh -c "cp /opt/resource/automations.yaml /opt/hass/"
sudo sh -c "cp /opt/resource/onboarding /opt/hass/.storage"
sudo sh -c "cp /opt/resource/auth /opt/hass/.storage"
sudo sh -c "cp -r /opt/resource/hacs /opt/hass/custom_components/"
sudo sh -c "rm -rf /opt/resource/*"

#修改OpenWRT为DHCP方式上网
if [ "$(cat /sys/class/net/eth0/carrier)" == "1" ]; then

  sleep 5
  sudo sh -c "docker exec -i OpenWRT  sed -i '14s/static/dhcp/' /etc/config/network"
  #清空OpenWRTroot用户密码
  sleep 5
  sudo sh -c "docker exec -i OpenWRT  passwd -d root"
fi

#为HomeBridge安装ip-camera依赖包
sleep 5
sudo sh -c "docker exec -i HomeBridge npm install -g homebridge-ip-camera"

#升级ESPHome
sleep 5
sudo sh -c "docker exec -i ESPHome pip2 install esphome --upgrade"

#安装snapcast
sudo apt-get install -y snapserver snapclient
sudo systemctl enable snapserver
sudo systemctl enable snapclient
sudo chmod -R 777 /var/lib/snapserver
sudo mkdir -p /var/run/snapserver
sudo chmod -R 777 /var/run/snapserver

#蓝牙连接自动启动
sudo useradd -M itcommander
sudo usermod -a -G audio itcommander
sudo sh -c "echo 'ACTION==\"add\" SUBSYSTEM==\"bluetooth\", KERNEL==\"hci0:11\", ENV{SYSTEMD_WANTS}+=\"bthelper@%k.service\" RUN+=\"/bin/bash /usr/local/bin/bt.sh\"' > /etc/udev/rules.d/90-pi-bluetooth.rules"
sudo sh -c "echo 'ACTION==\"remove\" SUBSYSTEM==\"bluetooth\", KERNEL==\"hci0:11\", ENV{SYSTEMD_WANTS}+=\"bthelper@%k.service\" RUN+=\"/bin/bash /usr/local/bin/btkill.sh\"' >> /etc/udev/rules.d/90-pi-bluetooth.rules"

#蓝牙音频设置
sudo sh -c "echo 'btmac=\$(sudo bluetoothctl info)
result=\$(echo \$btmac | grep "Missing")
echo \$result
if [[ \"\$result\" == \"\" ]]
then
btmac=\$(echo \$btmac | cut -c8-24)
echo \$btmac
sudo sh -c \"echo '\'\
pcm.speaker \{ type plug slave.pcm \{type bluealsa device '\''\"''$'btmac'\''\"' profile '\''\"'a2dp'\''\"'}\}\'' > /etc/asound.conf\"
fi
su - itcommander -c \"snapclient -s 1 >> /dev/null 2>&1 & \"
' > /usr/local/bin/bt.sh"
sudo sh -c "chmod +x /usr/local/bin/bt.sh"

sudo sh -c "echo 'sudo sh -c \"sudo killall -u itcommander\"' > /usr/local/bin/btkill.sh"
sudo sh -c "chmod +x /usr/local/bin/btkill.sh"

#设置音乐共享目录
echo "samba-common samba-common/workgroup string  WORKGROUP" | sudo debconf-set-selections
echo "samba-common samba-common/dhcp boolean true" | sudo debconf-set-selections
echo "samba-common samba-common/do_debconf boolean true" | sudo debconf-set-selections
sudo apt-get install -y samba
sudo systemctl enable smbd

sudo sh -c "echo '
[global]
workgroup = workgroup
server string = test
security = user
map to guest = Bad User

[Music]
path = /opt/mopidy
writeable = yes
guest ok = yes
browseble = yes
' > /etc/samba/smb.conf"

#sudo systemctl restart smbd

#清除启动脚本安装命令
sudo sh -c "sed -i '/docker.sh/d' /etc/rc.local"
sudo sh -c "sed -i '/docker.sh/d' /boot/rc-local"

#删除安装脚本（如果本地安装）
sudo rm -rf $runpath/docker.sh

#重启系统
echo "----------------------------------------------------------------------"

for i in $(seq -w 30 -1 0); do
  echo -en "||安装结束系统将会在\e[0;31m$i\e[0m秒内重启!||\r"
  sleep 1
done

#清理atp缓存
sudo apt-get clean

sudo reboot
