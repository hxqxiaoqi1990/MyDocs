#!/bin/bash
cat >limit.yaml<<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: limit-range
  namespace: $1
spec:
  limits:
  - default:
      cpu: 1
      memory: 1000Mi
    defaultRequest:
      cpu: 0.01
      memory: 10Mi
    type: Container
EOF
