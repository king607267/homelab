#!/bin/bash
ns="metallb-system"
currDir="$(dirname "$0")"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $ns
EOF
helm repo add metallb https://metallb.github.io/metallb
helm upgrade --install  metallb metallb/metallb --version "$metallb_version" -n $ns
kubectl wait --for=condition=Ready pod --all -n $ns --timeout=300s

echo "apply IPAddressPool"
kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: $metallb_pool_name
  namespace: $ns
spec:
  addresses:
    - $metallb_ip_pool
EOF
echo "apply L2Advertisement"
kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2advsement
  namespace: $ns
spec:
  ipAddressPools:
    - $metallb_pool_name
EOF