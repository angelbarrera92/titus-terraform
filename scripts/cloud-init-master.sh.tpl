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
apt-get update

curl -s https://8095c452e9473a3fae3ea86a6f2572c2cde0d7b5ec63e84f:@packagecloud.io/install/repositories/netflix/titus/script.deb.sh | bash
apt-get update
apt-get install -y openjdk-8-jdk mesos titus-executor titus-vpc-driver

# Download and install from my own git repository
curl -L -s -o /tmp/titus-server-master_0.0.1-1_all.deb https://github.com/angelbarrera92/titus-terraform/blob/master/deb/titus-server-master_0.0.1-1_all.deb?raw=true
dpkg -i /tmp/titus-server-master_0.0.1-1_all.deb


echo 'titus.master.apiport=7001' >> /opt/titus-server-master/titusmaster.properties
echo 'titus.master.apiProxyPort=7001' >> /opt/titus-server-master/titusmaster.properties
echo 'titus.master.grpcServer.port=7104' >> /opt/titus-server-master/titusmaster.properties
echo 'titus.zookeeper.connectString=${prereqs_ip}:2181' >> /opt/titus-server-master/titusmaster.properties
echo 'titus.zookeeper.root=/titus/main' >> /opt/titus-server-master/titusmaster.properties
echo 'mesos.master.location=${prereqs_ip}:5050' >> /opt/titus-server-master/titusmaster.properties
echo 'titus.agent.fullCacheRefreshIntervalMs=10000' >> /opt/titus-server-master/titusmaster.properties
echo 'titus.agent.agentServerGroupPattern=.*' >> /opt/titus-server-master/titusmaster.properties
echo 'titusMaster.job.configuration.defaultIamRole=${default_role_arn}' >> /opt/titus-server-master/titusmaster.properties
echo 'titusMaster.job.configuration.defaultSecurityGroups=${default_sg_id}' >> /opt/titus-server-master/titusmaster.properties
echo 'mesos.titus.executor=/apps/titus-executor/bin/titus-executor' >> /opt/titus-server-master/titusmaster.properties

echo '[Unit]' >> /lib/systemd/system/titus-server-master.service
echo 'Description=Titus Master' >> /lib/systemd/system/titus-server-master.service
echo '[Service]' >> /lib/systemd/system/titus-server-master.service
echo 'ExecStart=/opt/titus-server-master/bin/titus-server-master -p /opt/titus-server-master/titusmaster.properties' >> /lib/systemd/system/titus-server-master.service
echo '[Install]' >> /lib/systemd/system/titus-server-master.service
echo 'WantedBy=multi-user.target' >> /lib/systemd/system/titus-server-master.service

# later we probably want to re-enable the updates
systemctl enable titus-server-master
systemctl start titus-server-master
systemctl enable apt-daily.service
systemctl enable apt-daily.timer
reboot