#!/bin/bash
ns="longhorn-system"
if helm status longhorn -n $ns >/dev/null 2>&1; then
  kubectl -n $ns patch -p '{"value": "true"}' --type=merge lhs deleting-confirmation-flag
  helm uninstall longhorn -n $ns
  kubectl delete namespace $ns
fi