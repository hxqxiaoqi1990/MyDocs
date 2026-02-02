#!/bin/bash

Days=`kubeadm alpha certs check-expiration|grep admin.conf|awk '{print $7}'|awk -F 'd' '{print $1}'`
if [ $Days -lt 30 ];then
	/usr/bin/kubeadm alpha certs renew all
	/usr/bin/docker ps |grep -E 'k8s_kube-apiserver|k8s_kube-controller-manager|k8s_kube-scheduler|k8s_etcd_etcd' | awk -F ' ' '{print $1}' |xargs docker restart
	curl -X POST 'https://open.feishu.cn/open-apis/bot/v2/hook/7f52c85b-7b0c-415f-8428-5b548b3ee973' -H "Content-Type: application/json" -d '{"msg_type":"text","content":{"text":"告警：'"$1"'k8s证书不足'"$Days"'天"}}'
fi
