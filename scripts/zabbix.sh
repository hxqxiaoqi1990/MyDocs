#!/bin/bash

# 安装zabbix
yum -y install zabbix-agent-5.0.17-1.el7.x86_64.rpm
sed -i "s/ServerActive=127.0.0.1/ServerActive=183.134.214.86/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/Hostname=Zabbix server/Hostname=$1/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/Server=127.0.0.1/#Server=127.0.0.1/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/# StartAgents=3/StartAgents=0/g" /etc/zabbix/zabbix_agentd.conf
systemctl start zabbix-agent.service
systemctl enable zabbix-agent.service

# 安装netfilter指标
yum -y install bc
[ -d "/etc/zabbix/scripts/" ] && echo "dir exits" || mkdir -p /etc/zabbix/scripts/

cat > /etc/zabbix/scripts/netfilter.sh <<EOF
#!/bin/bash
max=\`cat /proc/sys/net/netfilter/nf_conntrack_max\`
count=\`cat /proc/sys/net/netfilter/nf_conntrack_count\`

echo "scale=2;\$count/\$max*100" | bc
EOF

cat > /etc/zabbix/zabbix_agentd.d/netfilter.conf <<EOF
UserParameter=parameter,/bin/bash /etc/zabbix/scripts/netfilter.sh
EOF

chmod +x /etc/zabbix/scripts/netfilter.sh

systemctl restart zabbix-agent.service

