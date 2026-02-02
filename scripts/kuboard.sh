cat >kuboard.yaml<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuboard
  namespace: kube-system
  annotations:
    k8s.kuboard.cn/displayName: kuboard
    k8s.kuboard.cn/ingress: "true"
    k8s.kuboard.cn/service: NodePort
    k8s.kuboard.cn/workload: kuboard
  labels:
    k8s.kuboard.cn/layer: monitor
    k8s.kuboard.cn/name: kuboard
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s.kuboard.cn/layer: monitor
      k8s.kuboard.cn/name: kuboard
  template:
    metadata:
      labels:
        k8s.kuboard.cn/layer: monitor
        k8s.kuboard.cn/name: kuboard
    spec:
      containers:
      - name: kuboard
        image: registry.cn-zhangjiakou.aliyuncs.com/moxi-k8s/kuboard
        imagePullPolicy: Always
        resources:
          limits:
            cpu: '1'
            memory: 1Gi
          requests:
            cpu: 100m
            memory: 100Mi
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
        operator: Exists

---
apiVersion: v1
kind: Service
metadata:
  name: kuboard
  namespace: kube-system
spec:
  type: ClusterIP
  ports:
  - name: http
    port: 80
    targetPort: 80
  selector:
    k8s.kuboard.cn/layer: monitor
    k8s.kuboard.cn/name: kuboard

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kuboard-user
  namespace: kube-system

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kuboard-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kuboard-user
  namespace: kube-system

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kuboard-viewer
  namespace: kube-system

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kuboard-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- kind: ServiceAccount
  name: kuboard-viewer
  namespace: kube-system

---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cluster-role-exec
rules:
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["get", "watch", "list" , "create"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kuboard-viewer-clusterrolebinding-exec
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-role-exec
subjects:
  - kind: ServiceAccount
    name: kuboard-viewer
    namespace: kube-system
EOF
