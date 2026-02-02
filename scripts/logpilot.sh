#!/bin/bash

cat >logpilot.yaml<<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-pilot
  labels:
    k8s-app: log-pilot
  namespace: default
spec:
  selector:
    matchLabels:
      k8s-app: log-pilot
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        k8s-app: log-pilot
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: log-pilot
        image: registry.cn-hangzhou.aliyuncs.com/acs/log-pilot:0.9.5-filebeat #没用最新镜像，是因为为了收集多行日志，需要修改log-pilot的源码，最新的镜像测试修改完后，pod无法启动，所以就放弃了，这个版本测试没有问题，修改配置会在下面介绍
        env:
          - name: "LOGGING_OUTPUT"
            value: "logstash"
          - name: "LOGSTASH_HOST"
            value: "183.134.214.86"
          - name: "LOGSTASH_PORT"
            value: "15044"
          - name: "LOGSTASH_LOADBALANCE"
            value: "true"
          - name: "NODE_NAME"
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
        resources:
          limits:
            cpu: 1000m
            memory: 1000Mi
          requests:
            cpu: 250m
            memory: 128Mi
        volumeMounts:
        - name: sock
          mountPath: /var/run/docker.sock
        - name: logs
          mountPath: /var/log/filebeat
        - name: state
          mountPath: /var/lib/filebeat
        - name: root
          mountPath: /host
          readOnly: true
        - name: localtime
          mountPath: /etc/localtime
        securityContext:
          capabilities:
            add:
            - SYS_ADMIN
      terminationGracePeriodSeconds: 30
      volumes:
      - name: sock
        hostPath:
          path: /var/run/docker.sock
      - name: logs
        hostPath:
          path: /var/log/filebeat
      - name: state
        hostPath:
          path: /var/lib/filebeat
      - name: root
        hostPath:
          path: /
      - name: localtime
        hostPath:
          path: /etc/localtime
EOF
