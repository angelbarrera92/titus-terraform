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
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y docker-ce
usermod -aG docker ubuntu

docker run -d -p 2181:2181 --name zookeeper jplock/zookeeper:3.4.10
sleep 10
docker run -d -p 5050:5050 --net=host --name mesomaster mesosphere/mesos-master:1.0.1-2.0.93.ubuntu1404 mesos-master --zk=zk://localhost:2181/titus/mainvpc/mesos --work_dir=/tmp/master --log_dir=/var/log/mesos --logging_level=INFO --quorum=1

# later we probably want to re-enable the updates
systemctl enable apt-daily.service
systemctl enable apt-daily.timer
