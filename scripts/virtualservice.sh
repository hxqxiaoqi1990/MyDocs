#!/bin/bash
cat >virtualservice.yaml<<EOF
kind: VirtualService
apiVersion: networking.istio.io/v1alpha3
metadata:
  name: virtualservice
  namespace: default
spec:
  hosts:
    - '*'
  gateways:
    - gateway
  # 配置路由规则
  http:
    - match:
        - uri:
            prefix: /allinone/
      rewrite:
        uri: /
      route:
        - destination:
            host: java-card-gate.moxi-game.svc.cluster.local
            port:
              number: 8080
EOF
