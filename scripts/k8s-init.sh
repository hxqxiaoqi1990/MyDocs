#!/bin/bash

# docker版本，k8s版本
#DockerV='-18.09.9'
DockerV='-19.03.15'
K8sV='-1.19.9'

yum install -y yum-utils device-mapper-persistent-data lvm2 epel-release vim screen bash-completion mtr lrzsz wget telnet zip unzip sysstat  ntpdate libcurl openssl bridge-utils nethogs dos2unix iptables-service net-tools

wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

wget http://mirrors.aliyun.com/repo/epel-7.repo -O /etc/yum.repos.d/epel.repo

cat >>/etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

#安装K8S组件
yum install -y kubelet${K8sV} kubeadm${K8sV} kubectl${K8sV} docker-ce${DockerV}

systemctl enable kubelet

mkdir -p /etc/docker

tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://docker.1ms.run","https://docker.ckyl.me","https://docker.hpcloud.cloud","https://docker.m.daocloud.io","https://cf-workers-docker-io-470.pages.dev","https://mirror.ccs.tencentyun.com","https://pthx0mbz.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-opts": {
    "max-size": "200m",
    "max-file": "10"
    }
}
EOF

systemctl restart docker && systemctl enable docker

#禁用防火墙与selinux

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config

service firewalld stop
systemctl disable firewalld.service
service iptables stop
systemctl disable iptables.service

service postfix stop
systemctl disable postfix.service

wget http://mirrors.aliyun.com/repo/epel-7.repo -O /etc/yum.repos.d/epel.repo

echo '/etc/security/limits.conf 参数调优，需重启系统后生效'

cp -rf /etc/security/limits.conf /etc/security/limits.conf.back

cat > /etc/security/limits.conf << EOF
* soft nofile 655350
* hard nofile 655350
* soft nproc unlimited
* hard nproc unlimited
* soft core unlimited
* hard core unlimited
root soft nofile 655350
root hard nofile 655350
root soft nproc unlimited
root hard nproc unlimited
root soft core unlimited
root hard core unlimited
EOF

echo '/etc/sysctl.conf 文件调优'

cp -rf /etc/sysctl.conf /etc/sysctl.conf.back
cat > /etc/sysctl.conf << EOF
vm.swappiness = 0
kernel.sysrq = 1

net.ipv4.neigh.default.gc_stale_time = 120
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2

net.ipv4.tcp_max_tw_buckets = 20000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.vs.conn_reuse_mode = 0

net.netfilter.nf_conntrack_max=2048576
net.netfilter.nf_conntrack_tcp_timeout_established=3600
fs.inotify.max_user_watches=1048576
fs.inotify.max_user_instances=1024
EOF

echo "ipvs模块开启"
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF

echo "1">/proc/sys/net/bridge/bridge-nf-call-iptables

chmod 755 /etc/sysconfig/modules/ipvs.modules
bash /etc/sysconfig/modules/ipvs.modules

lsmod | grep -e ip_vs -e nf_conntrack_ipv4

echo "禁用swap"
swapoff -a
sed -i '/swap/d' /etc/fstab

sysctl -p

if [ `cat /proc/sys/net/netfilter/nf_conntrack_max` -eq 2048576 ];then
	echo "内核配置成功"
	echo "内核配置成功" > /root/k8s-install.log
else
        echo "内核配置失败"
fi
