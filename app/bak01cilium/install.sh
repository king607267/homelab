#!/bin/bash
ns="cilium"
#if kubectl get daemonset -A | grep -q cilium; then
#    echo "已安装"
#else
#    echo "未安装"
#fi
#https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/#gs-gateway-api
#https://kubito.dev/posts/gateway-api-setup-cilium-load-balancing/
#https://isovalent.com/blog/post/migrating-from-metallb-to-cilium/#use-cases-for-metallb
#helm repo add cilium https://helm.cilium.io/
helm upgrade --install cilium cilium/cilium --version "$cilium_version" \
   --namespace $ns --create-namespace \
   --reuse-values \
   --set operator.replicas=1 \
   --set envoy.enabled=true \
   --set debug.enabled=true \
   --set debug.verbose=flow \
   --set l2announcements.enabled=true \
   --set kubeProxyReplacement=true \
   --set hubble.enabled=true \
   --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true \
   --set k8sServiceHost="$cilium_k8s_service_host" \
   --set k8sServicePort=6443 \
   --set gatewayAPI.enabled=true

#kubectl -n $ns rollout restart deployment/cilium-operator
#kubectl -n $ns rollout restart ds/cilium
kubectl wait --for=condition=Ready pod --all -n $ns --timeout=600s
kubectl -n $ns exec ds/cilium -- cilium-dbg config --all | grep EnableL2Announcements

#https://doc.crds.dev/github.com/cilium/cilium@1.18.4
kubectl apply -f - <<EOF
apiVersion: cilium.io/v2
kind: CiliumLoadBalancerIPPool
metadata:
  name: cilium-ip-pool
  namespace: $ns
spec:
  blocks:
  - cidr: $cilium_cidr
  serviceSelector:
    matchLabels:
      "io.kubernetes.service.namespace": "$gateway_namespace"
EOF
kubectl apply -f - <<EOF
apiVersion: cilium.io/v2alpha1
kind: CiliumL2AnnouncementPolicy
metadata:
  name: cilium-l2advertisement-policy
  namespace: $ns
spec:
  serviceSelector:
    matchLabels:
      "io.kubernetes.service.namespace": "$gateway_namespace"
  interfaces:
  - ^eth[0-9]+
  - ^enp[0-9]+
  - ^ens[0-9]
  externalIPs: true
  loadBalancerIPs: true
EOF