#!/bin/bash
currDir="$(dirname "$0")"
workDir="chart_$gateway_namespace"
gitRpo="https://github.com/king607267/homelab-gateway.git"
if [ ! -d "$currDir/$workDir" ]; then
  git clone $gitRpo "$currDir/$workDir"
else
  git -C "$currDir/$workDir" pull
fi

#helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm --version v0.0.0-latest -n envoy-gateway-system --create-namespace

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $gateway_namespace
  labels:
    shared-gateway-access: "true"
EOF
#https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/#gs-gateway-api
helm upgrade --install home-gateway "$currDir/$workDir" -n "$gateway_namespace" -f - <<EOF
gateway:
  address:
    ip: $gateway_ip
  tls:
    enable: true
    secretName: main-gateway-issued-secret
    dnsNames:
      - "$domain_grafana"
      - "$domain_prome"
      - "$domain_nas"
      - "$domain_headlamp"
      - "$domain_wow"
      - "$domain_wow_wotlk"
      - "$domain_wow_tbc"
      - "$domain_wow_classic"
      - "$domain_kubeshark"
      - "$domain_longhorn"

gatewayClass :
  enabled: true
  name: main-gateway-class
  #io.cilium/gateway-controller
  controllerName: gateway.envoyproxy.io/gatewayclass-controller

#gatewayClass :
#  enabled: false
#  name: cilium

routers:
#http routing
  - name: $domain_https_route_name
    protocol: HTTPS
    port: $gateway_port_https
    matchLabels: "shared-gateway-access: 'true'"
  - name: $domain_http_route_name
    protocol: HTTP
    port: $gateway_port_http
    matchLabels: "shared-gateway-access: 'true'"
#  - name: shared-tls
#    protocol: TLS
#    port: $gateway_port_https
#    matchLabels: "shared-gateway-access: 'true'"
  #wow-wotlk
  - name: wotlk-server
    protocol: TCP
    port: 8008
    hostname:
    matchLabels: "kubernetes.io/metadata.name: wow"
  - name: wotlk-realmd
    protocol: TCP
    port: 3780
    hostname:
    matchLabels: "kubernetes.io/metadata.name: wow"
    #wow-tbc
  - name: tbc-server
    protocol: TCP
    port: 8070
    hostname:
    matchLabels: "kubernetes.io/metadata.name: wow"
  - name: tbc-realmd
    protocol: TCP
    port: 3770
    hostname:
    matchLabels: "kubernetes.io/metadata.name: wow"
    #wow-classic
  - name: classic-server
    protocol: TCP
    port: $wow_classic_realm_port
    hostname:
    matchLabels: "kubernetes.io/metadata.name: wow"
  - name: classic-realmd
    protocol: TCP
    port: 3760
    hostname:
    matchLabels: "kubernetes.io/metadata.name: wow"
    #dsm-dsm
  - name: dsm-terminal
    protocol: TCP
    port: "$vdsm_ssh_port"
    hostname:
    matchLabels: "kubernetes.io/metadata.name: dsm"
EOF

#kubectl wait --for=condition=Ready certificate --all -n home-gateway --timeout=300s