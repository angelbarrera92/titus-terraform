#!/bin/bash

set -x
sleep 60

# ok you had your chance... kill all the things
systemctl disable apt-daily.service
systemctl disable apt-daily.timer
echo 'Disabling dpkg lock apt-daily, removing locks now via ps and kill'
ps aux | grep /var/lib/dpkg/lock | awk {'print $2'} | xargs kill -9
lsof | grep /var/lib/dpkg/lock | awk {'print $2'} | xargs kill -9
lsof | grep /usr/bin/dpkg | awk {'print $2'} | xargs kill -9
rm -f /var/lib/dpkg/lock
echo 'Disabling apt archives lock, via ps and kill'
ps aux | grep /var/cache/apt/archives/lock | awk {'print $2'} | xargs kill -9
ps aux | grep apt | awk {'print $2'} | xargs kill -9
ps aux | grep /var/cache/apt/archives/lock | awk {'print $2'} | xargs kill -9
lsof | grep /var/cache/apt/archives/lock | awk {'print $2'} | xargs kill -9
rm -f /var/cache/apt/archives/lock
# let dpkg (the underlying component of apt) reconfigure it's self
dpkg — configure -a
# now we can call apt for stuff, -y means yes...
# -y is not needed if you set DEBIAN_FRONTEND=noninteractive
curl -s https://8095c452e9473a3fae3ea86a6f2572c2cde0d7b5ec63e84f:@packagecloud.io/install/repositories/netflix/titus/script.deb.sh | bash
apt-get update
apt-get install -y openjdk-8-jdk
# Download and install from my own git repository
curl -L -s -o /tmp/titus-server-gateway_0.0.1-1_all.deb https://github.com/angelbarrera92/titus-terraform/blob/master/deb/titus-server-gateway_0.0.1-1_all.deb?raw=true
dpkg -i /tmp/titus-server-gateway_0.0.1-1_all.deb


echo 'titus.gateway.masterIp=${master_ip}' >> /opt/titus-server-gateway/titusgateway.properties
echo 'titus.gateway.masterHttpPort=7001' >> /opt/titus-server-gateway/titusgateway.properties

echo '[Unit]' >> /lib/systemd/system/titus-server-gateway.service
echo 'Description=Titus Gateway' >> /lib/systemd/system/titus-server-gateway.service
echo '[Service]' >> /lib/systemd/system/titus-server-gateway.service
echo 'ExecStartPre=/bin/mkdir -p /var/log/titus-server-gateway' >> /lib/systemd/system/titus-server-gateway.service
echo 'Restart=always' >> /lib/systemd/system/titus-server-gateway.service
echo 'StartLimitInterval=0' >> /lib/systemd/system/titus-server-gateway.service
echo 'RestartSec=5' >> /lib/systemd/system/titus-server-gateway.service
echo 'ExecStart=/opt/titus-server-gateway/bin/titus-server-gateway -p /opt/titus-server-gateway/titusgateway.properties' >> /lib/systemd/system/titus-server-gateway.service


# later we probably want to re-enable the updates
systemctl enable titus-server-gateway
systemctl start titus-server-gateway
systemctl enable apt-daily.service
systemctl enable apt-daily.timer
reboot