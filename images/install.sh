#!/bin/bash

init (){
        echo "Initializing ECS..."
        bash -c "$(curl -SsL https://xxx.com/ops/k8s-init.sh)"
}

conf_yum (){
        echo "Configuring YUM resource..."
        curl -o /etc/yum.repos.d/CentOS-Base.repo https://repo.huaweicloud.com/repository/conf/CentOS-7-reg.repo
        yum clean all && yum makecache
}

conf_docker (){
        echo "Installing Docker..."
        bash -c "$(curl -SsL https://xxx.com/ops/docker.sh)" @ $1
}

master (){
        echo "Initializing master node with api_ip=$1, pod_ip=$2, svc_ip=$3..."
        bash -c "$(curl -SsL https://xxx.com/ops/kubeadm-init.sh)" @ $1 $2 $3
        echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
        source ~/.bash_profile
        kubeadm init --config kubeadm-init.yaml
        sysctl -p
}

get_flannel (){
        echo "Getting Flannel file..."
        [ -e /opt/cni/bin/flannel ] || wget -O /opt/cni/bin/flannel https://xxx.com/ops/flannel
        chmod +x /opt/cni/bin/flannel
}

flannel (){
        echo "Installing Flannel network plugin with pod_ip=$1..."
        source .bash_profile
        bash -c "$(curl -SsL https://xxx.com/ops/kube-flannel.sh)" @ $1
        kubectl apply -f kube-flannel.yml
}

health (){
        echo "Repairing Kubernetes control plane health checks..."
        sed -i '/--port=0/d' /etc/kubernetes/manifests/kube-controller-manager.yaml
        sed -i '/--port=0/d' /etc/kubernetes/manifests/kube-scheduler.yaml
        systemctl restart kubelet
}

istio (){
        echo "Installing Istio, Prometheus, and Kiali..."
        source ~/.bash_profile
        [ -e $PWD/istio-1.9.9-edit.tar.gz ] || wget https://xxx.com/ops/istio-1.9.9-edit.tar.gz
        tar xf istio-1.9.9-edit.tar.gz
        $PWD/istio-1.9.9/bin/istioctl install --set profile=demo --set values.global.hub=registry.cn-zhangjiakou.aliyuncs.com/moxi-k8s --set values.global.proxy.holdApplicationUntilProxyStarts=true --set values.global.imagePullPolicy=IfNotPresent -y
        kubectl apply -f $PWD/istio-1.9.9/samples/addons/prometheus.yaml
        kubectl apply -f $PWD/istio-1.9.9/samples/addons/kiali.yaml
        sleep 2
        kubectl apply -f $PWD/istio-1.9.9/samples/addons/kiali.yaml
        kubectl -n istio-system patch service istio-ingressgateway -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 8080, "nodePort": 30000}]}}}'
}

conf_istio (){
        echo "Configuring Istio gateway, virtualservice, and compression..."
        source .bash_profile
        bash -c "$(curl -SsL https://xxx.com/ops/gateway.sh)"
        bash -c "$(curl -SsL https://xxx.com/ops/virtualservice.sh)"
        bash -c "$(curl -SsL https://xxx.com/ops/gateway-gzip.sh)"
        kubectl apply -f gateway.yaml
        kubectl apply -f virtualservice.yaml
        kubectl apply -f gateway-gzip.yaml
}

kuboard (){
        echo "Installing Kuboard and Metrics Server..."
        source .bash_profile
        bash -c "$(curl -SsL https://xxx.com/ops/kuboard.sh)"
        bash -c "$(curl -SsL https://xxx.com/ops/metrics-server.sh)"
        kubectl apply -f kuboard.yaml
        kubectl apply -f metrics-server.yaml
        # 获取token
        echo $(kubectl -n kube-system get secret $(kubectl -n kube-system get secret | grep kuboard-user | awk '{print $1}') -o go-template='{{.data.token}}' | base64 -d)
}

completion (){
        echo "Enabling Bash completion for kubectl..."
        yum install -y bash-completion
        sleep 2
        source /usr/share/bash-completion/bash_completion
        source <(kubectl completion bash)
        echo "source <(kubectl completion bash)" >> ~/.bashrc
}

limit (){
        echo "Limiting pod resources and creating namespace $1..."
        source .bash_profile
        # 限制容器资源
        bash -c "$(curl -SsL https://xxx.com/ops/limit.sh)" @ $1
        kubectl create ns $1
        kubectl apply -f limit.yaml
}

zabbix (){
        echo "Installing Zabbix agent with local ip=$1..."
        [ -e $PWD/zabbix-agent-5.0.17-1.el7.x86_64.rpm ] || wget https://xxx.com/ops/zabbix-agent-5.0.17-1.el7.x86_64.rpm
        bash -c "$(curl -SsL https://xxx.com/ops/zabbix.sh)" @ $1
}

alertmanager (){
        echo "Installing AlertManager and kube-state-metrics..."
        source .bash_profile
        bash -c "$(curl -SsL https://xxx.com/ops/alertmanager.sh)"
        kubectl apply -f alertmanager.yaml
}

cert (){
        echo "Configuring SSL certificate check cron job for project $1..."
        [ -d /scripts ] || mkdir /scripts
        wget -O /scripts/cert.sh https://xxx.com/ops/cert.sh
        echo "0 3 * * * /usr/bin/bash /scripts/cert.sh "$1" &> /dev/null" >> /var/spool/cron/root
        source .bash_profile
}

del_images (){
        echo "Configuring old image cleanup cron job..."
        [ -d /scripts ] || mkdir /scripts
        wget -O /scripts/clear_images.sh https://xxx.com/ops/clear_images.sh
        echo "0 3 * * * /bin/bash /scripts/clear_images.sh" >> /var/spool/cron/root
}

kube-state-metrics (){
        echo "Installing kube-state-metrics..."
        source .bash_profile
        bash -c "$(curl -SsL https://xxx.com/ops/kube-state-metrics.sh)"
        kubectl apply -f kube-state-metrics.yaml
}

logpilot (){
        echo "Installing LogPilot..."
        source .bash_profile    
        bash -c "$(curl -SsL https://xxx.com/ops/logpilot.sh)"
        kubectl apply -f logpilot.yaml
}

install_nginx (){
        curl -Ss -O https://xxx.com/ops/nginx.yaml
        kubectl apply -f nginx.yaml
}

install_elk (){
        echo "Installing elk..."
	[ -d /data/elk ] || mkdir -p /data/elk /data/elk/data /data/elk/plugins
	[ -e /data/elk/elk.tar.gz ] || wget -O /data/elk/elk.tar.gz https://xxx.com/ops/elk.tar.gz
	tar xf /data/elk/elk.tar.gz -C /data/elk/
	chown -R 1000:1000 /data/elk/
    	if command -v docker &> /dev/null; then
		cd /data/elk/ && docker compose up -d
    	else
		echo "install docker!!!"
	fi
}


function menu(){
cat <<-EOF
===================== List ========================
1）set hostname
2）init ECS
3）install master
4）install flannel
5）get flannel file
6）repair k8s cs
7）crontab check ssl cert
8）install istio prometheus kiali
9）config istio: gateway，virtualservice，compression
10）install kuboard and nginx
11）install zabbix
12）install alertmanager and kube-state-metrics
13）limit pod and create namespace
14）config yum resource
15）install docker
16）enable bash completion
17）crontab delete images
18) install logpilot
19) elk
q) quit
==================================================
EOF
}

# 设置密码校验
while true
do
read -s -p "password: " password
if [ "$password" = "123123" ];then
        echo "Success"
	break
else
        echo "password error, Please re-enter!"
        continue
fi
done

# 主功能列表
while true
do
menu
read -p "input number: " i
case $i in
        "1")
                read -p "input host name, default(k8s-master): " name
		name=${name:-"k8s-master"}
		hostnamectl set-hostname $name
        ;;
        "2")
                init
        ;;
        "3")
                read -p "input api_ip, example(192.168.40.101:6443): " api_ip
                read -p "input pod_ip, default(10.244.0.0/16): " pod_ip
                read -p "input svc_ip, default(10.96.0.0/12): " svc_ip
                if [ -z "$api_ip" ] ; then
                        echo "Error: Missing required inputs. Please provide api_ip, pod_ip, and svc_ip."
                        continue
                fi
                pod_ip=${pod_ip:-"10.244.0.0/16"}
                svc_ip=${svc_ip:-"10.96.0.0/12"}
                master $api_ip $pod_ip $svc_ip
        ;;
        "4")
                read -p "input pod_ip, default(10.244.0.0/16): " pod_ip
		pod_ip=${pod_ip:-"10.244.0.0/16"}
                flannel $pod_ip
        ;;
        "5")
                get_flannel
        ;;
        "6")
                health
        ;;
        "7")
                read -p "input project name(xmty): " project
                if [ -z "$project" ]; then
                        echo "Error: Missing required input. Please provide project name."
                        continue
                fi
                cert $project
        ;;
        "8")
                read -p "Please add a node or remove the master taint before executing，Press Enter to continue" tishi
                istio
        ;;
        "9")
                conf_istio
        ;;
        "10")
                echo "install kuboard and nginx"
                kuboard
                install_nginx
        ;;
        "11")
                read -p "input local ip(jushita-192.168.0.1): " local_ip
                if [ -z "$local_ip" ]; then
                        echo "Error: Missing required input. Please provide local ip."
                        continue
                fi
                zabbix $local_ip
        ;;
        "12")
                alertmanager
                kube-state-metrics
        ;;
        "13")
                read -p "input namespace: " namespace
                limit $namespace
        ;;
        "14")
                conf_yum
        ;;
        "15")
                read -p "input region(hz|txy|hwy|aly), default(aly): " region
		region=${region:-"aly"}
                conf_docker $region
        ;;
        "16")
                completion
        ;;
        "17")
                del_images
        ;;
        "18")
                logpilot
        ;;
        "19")
                install_elk
        ;;
        "q")
                exit 0
        ;;
        *)
                echo "input error"
        ;;
esac
done

