#!/bin/bash
ns="nfs"
#https://gateway-api.sigs.k8s.io/guides/#installing-a-gateway-controller
if helm status nfs-subdir-external-provisioner -n $ns >/dev/null 2>&1; then
  helm delete nfs-subdir-external-provisioner -n $ns
fi