#!/bin/bash

cat > kubeadm-init.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.19.9
apiServer:
controlPlaneEndpoint: $1
networking:
  dnsDomain: cluster.local
  podSubnet: $2
  serviceSubnet: $3
imageRepository: registry.cn-zhangjiakou.aliyuncs.com/moxi-k8s
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  excludeCIDRs: null
  minSyncPeriod: 0s
  scheduler: "rr"
  strictARP: false
  syncPeriod: 30s
EOF
