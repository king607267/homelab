#!/bin/bash
ns="cert-manager"
if helm status cert-manager -n $ns >/dev/null 2>&1; then
  helm delete cert-manager -n $ns
fi
if helm status alidns-webhook -n $ns >/dev/null 2>&1; then
  helm delete alidns-webhook -n $ns
fi