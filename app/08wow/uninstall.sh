#!/bin/bash
ns="wow"
#https://gateway-api.sigs.k8s.io/guides/#installing-a-gateway-controller
if helm status classic -n $ns >/dev/null 2>&1; then
  helm delete classic -n $ns
fi

if helm status tbc -n $ns >/dev/null 2>&1; then
  helm delete tbc -n $ns
fi

if helm status wotlk -n $ns >/dev/null 2>&1; then
  helm delete wotlk -n $ns
fi