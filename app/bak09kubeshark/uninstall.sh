#!/bin/bash
ns="kubeshark"
#https://gateway-api.sigs.k8s.io/guides/#installing-a-gateway-controller
if helm status kubeshark -n $ns >/dev/null 2>&1; then
  helm delete kubeshark -n $ns
fi