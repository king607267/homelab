#!/bin/bash
set -eo pipefail
kubectl get configmap coredns -n kube-system -o yaml | sed 's|forward . /etc/resolv.conf|forward . '$TF_VAR_dns_server'|g' | kubectl apply -f -