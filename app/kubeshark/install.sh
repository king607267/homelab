#!/bin/bash
#https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/
ns="kubeshark"
currDir="$(dirname "$0")"
service_name="kubeshark-front"
workDir="chart_$ns"

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $ns
  labels:
    shared-gateway-access: "true"
EOF

gitRpo="git@github.com:kubeshark/kubeshark.git --depth 1 --branch $kubeshark_version"
if [ ! -d "$currDir/$workDir" ]; then
  git clone $gitRpo "$currDir/$workDir"
else
  git -C "$currDir/$workDir" pull
fi

helm upgrade --install $ns "$currDir/$workDir/helm-chart" -n $ns

kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: kubeshark-http-route
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
    - $domain_kubeshark
  rules:
    - backendRefs:
        - name: $service_name
          port: 80
      timeouts:
        request: 0s
        backendRequest: 0s
EOF