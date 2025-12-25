#!/bin/bash
ns="headlamp"
service_name="my-headlamp"
currDir="$(dirname "$0")"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $ns
  labels:
    shared-gateway-access: "true"
EOF
helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
helm upgrade --install my-headlamp headlamp/headlamp --version "$headlamp_version" -n $ns --wait --timeout=300s

kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: headlamp-http-route
  namespace: $ns
spec:
  parentRefs:
    - name: $gateway_name
      namespace: $gateway_namespace
      sectionName: $domain_http_route_name
    - name: $gateway_name
      namespace: $gateway_namespace
      sectionName: $domain_https_route_name
  hostnames:
    - $domain_headlamp
  rules:
    - backendRefs:
        - name: $service_name
          port: 80
      timeouts:
        request: 0s
        backendRequest: 0s
EOF
#
#kubectl apply -f - <<EOF
#apiVersion: gateway.networking.k8s.io/v1alpha2
#kind: TLSRoute
#metadata:
#  name: headlamp-tls-route
#  namespace: $ns
#spec:
#  hostnames:
#    - $domain_headlamp
#  parentRefs:
#    - group: gateway.networking.k8s.io
#      kind: Gateway
#      name: $gateway_name
#      namespace: $gateway_namespace
#      port: 777
#      sectionName: shared-tls
#  rules:
#    - backendRefs:
#        - name: $service_name
#          port: 80
#          weight: 1
#EOF

#https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: $ns
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: $ns
---
apiVersion: v1
kind: Secret
metadata:
  name: admin-user
  namespace: $ns
  annotations:
    kubernetes.io/service-account.name: "admin-user"
type: kubernetes.io/service-account-token
EOF
kubectl get secret admin-user -n $ns -o jsonpath="{.data.token}" | base64 -d > "$currDir/admin-user-token"