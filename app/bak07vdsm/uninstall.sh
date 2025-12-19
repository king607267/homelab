#!/bin/bash
ns="dsm"
#https://gateway-api.sigs.k8s.io/guides/#installing-a-gateway-controller
if helm status dsm -n $ns >/dev/null 2>&1; then
  helm delete dsm -n $ns
fi