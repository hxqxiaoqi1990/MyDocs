#!/bin/bash

cat >alertmanager.yaml<<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: istio-system
  name: alertmanager
  annotations:
    k8s.kuboard.cn/workload: alertmanager
    deployment.kubernetes.io/revision: '1'
    k8s.kuboard.cn/ingress: 'false'
    k8s.kuboard.cn/service: ClusterIP
  labels:
    k8s.kuboard.cn/layer: ''
    k8s.kuboard.cn/name: alertmanager
spec:
  selector:
    matchLabels:
      k8s.kuboard.cn/layer: ''
      k8s.kuboard.cn/name: alertmanager
  revisionHistoryLimit: 10
  template:
    metadata:
      labels:
        k8s.kuboard.cn/layer: ''
        k8s.kuboard.cn/name: alertmanager
    spec:
      securityContext:
        seLinuxOptions: {}
      imagePullSecrets: []
      restartPolicy: Always
      initContainers: []
      containers:
        - image: registry.cn-zhangjiakou.aliyuncs.com/moxi-k8s/alertmanager:v0.21.0
          imagePullPolicy: IfNotPresent
          name: alertmanager
          volumeMounts:
            - name: conf
              readOnly: true
              mountPath: /etc/alertmanager/alertmanager.yml
              subPath: alertmanager.yml
          resources:
            limits:
              cpu: '1'
              memory: 1Gi
            requests:
              cpu: 100m
              memory: 100Mi
          env: []
          lifecycle: {}
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
      volumes:
        - name: conf
          configMap:
            name: alertmanager-conf
            items:
              - key: alertmanager.yml
                path: alertmanager.yml
            defaultMode: 420
      dnsPolicy: ClusterFirst
      dnsConfig: {}
      schedulerName: default-scheduler
      terminationGracePeriodSeconds: 30
  progressDeadlineSeconds: 600
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  replicas: 1

---
apiVersion: v1
kind: Service
metadata:
  namespace: istio-system
  name: alertmanager
  annotations:
    k8s.kuboard.cn/workload: alertmanager
  labels:
    k8s.kuboard.cn/layer: ''
    k8s.kuboard.cn/name: alertmanager
spec:
  selector:
    k8s.kuboard.cn/layer: ''
    k8s.kuboard.cn/name: alertmanager
  type: ClusterIP
  ports:
    - port: 9093
      targetPort: 9093
      protocol: TCP
      name: 8jxjpr
      nodePort: 0
  sessionAffinity: None

---
metadata:
  name: alertmanager-conf
  namespace: istio-system
  managedFields:
    - manager: Mozilla
      operation: Update
      apiVersion: v1
      time: '2022-10-20T02:45:57Z'
      fieldsType: FieldsV1
      fieldsV1:
        'f:data':
          .: {}
          'f:alertmanager.yml': {}
data:
  alertmanager.yml: |-
    global:
    # 在指定时间内没有新的事件就发送恢复通知
      resolve_timeout: 5m
    route:
    # 默认的接收器名称
      receiver: 'webhook_mention_all'
    # 在组内等待所配置的时间，如果同组内，30秒内出现相同报警，在一个组内出现。
      group_wait: 30s
    # # 如果组内内容不变化，5m后发送。
      group_interval: 5m
    # 发送报警间隔，如果指定时间内没有修复，则重新发送报警
      repeat_interval: 24h
    # # 报警分组，根据 prometheus 的 lables 进行报警分组，这些警报会合并为一个通知发送给接收器，也就是警报分组。
      group_by: ['alertname']
      routes:
      - receiver: 'webhook_mention_all'
        group_wait: 10s
    receivers:
    - name: 'webhook_mention_all'
      webhook_configs:
    # 飞书报警
      - url: 'http://183.134.214.86:18087/prometheusalert?type=fs&tpl=prometheus-fsv2&fsurl=https://open.feishu.cn/open-apis/bot/v2/hook/7f52c85b-7b0c-415f-8428-5b548b3ee973'
kind: ConfigMap
apiVersion: v1
EOF
