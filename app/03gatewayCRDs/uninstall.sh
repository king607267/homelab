#!/bin/bash
#https://gateway-api.sigs.k8s.io/guides/#installing-a-gateway-controller
kubectl delete -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/$gateway_ver/experimental-install.yaml"