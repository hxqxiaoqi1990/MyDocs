#!/bin/bash

yum -y install wget
yum -y remove docker*
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum -y install docker-ce

mkdir -p /etc/docker
if [ "$1" = "txy" ];then
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://mirror.ccs.tencentyun.com"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-opts": {
    "max-size": "100m",
    "max-file": "10"
    }
}
EOF
else
tee /etc/docker/daemon.json <<-'EOF'
{
  "log-opts": {
    "max-size": "100m",
    "max-file": "7"
  },
  "data-root": "/var/lib/docker",
  "registry-mirrors": [
    "https://dockerproxy.cn"
  ]
}
EOF
fi

systemctl restart docker && systemctl enable docker
