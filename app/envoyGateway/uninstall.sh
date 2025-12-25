#!/bin/bash
ns="envoy-gateway-system"
#https://gateway-api.sigs.k8s.io/guides/#installing-a-gateway-controller
if helm status eg -n $ns >/dev/null 2>&1; then
  helm delete eg -n $ns
fi