#!/bin/bash
ns="longhorn-system"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $ns
  labels:
    shared-gateway-access: "true"
EOF

helm repo add longhorn https://charts.longhorn.io
helm upgrade --install longhorn longhorn/longhorn -n $ns

kubectl apply  -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: $ns-http-route
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
    - $domain_longhorn
  rules:
    - backendRefs:
        - name: longhorn-frontend
          port: 80
      timeouts:
        request: 0s
        backendRequest: 0s
EOF