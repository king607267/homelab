#!/bin/bash
ns="monitoring"
chart_name="prome-stack"
service_name_grafana="$chart_name-grafana"
service_name_prome="$chart_name-kube-prometheu-prometheus"
currDir="$(dirname "$0")"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $ns
  labels:
    shared-gateway-access: "true"
EOF
helm repo add $chart_name https://prometheus-community.github.io/helm-charts
helm upgrade --install $chart_name oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack -n $ns --version "$prome_version" --wait --timeout=300s \
-f - <<EOF
defaultRules:
  create: true
  rules:
    kubeControllerManager: false
    kubeProxy: false
    kubeSchedulerAlerting: false
    kubeSchedulerRecording: false

additionalPrometheusRulesMap:
  rule-name:
    groups:
      - name: homelab-IaC
        rules:
          - alert: InstanceDown
            expr: up == 0
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Instance [{{ $labels.instance }}] down"
              description: "[{{ $labels.instance }}] of job {{ $labels.job }} has been down for more than 5 minutes."

alertmanager:
  config:
    global:
      smtp_smarthost: $prome_smtp_smarthost
      smtp_from: $prome_email_from
      smtp_auth_username: $prome_smtp_auth_username
      smtp_auth_password: $prome_smtp_auth_password
    route:
      group_by: ['cluster']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 1h
      receiver: 'null'
      routes:
      - receiver: 'k3s-alerts'
        matchers:
          - severity =~ "warning|critical"
    receivers:
    - name: 'null'
    - name: 'k3s-alerts'
      email_configs:
        - to: '$prome_email_to'
          send_resolved: true

grafana:
  defaultDashboardsTimezone: $prome_grafana_timezone

kubeControllerManager:
  enabled: fasle

kubeScheduler:
  enabled: false

kubeProxy:
  enabled: false

prometheus:
  prometheusSpec:
    additionalScrapeConfigs:
#      - job_name: 'nas2_down'
#        static_configs:
#          - targets: [ 'nas2:9100' ]
#      - job_name: 'nas_down'
#        static_configs:
#          - targets: [ 'nas:9100' ]
#      - job_name: 'unraid_down'
#        static_configs:
#          - targets: [ 'unraid:9100' ]
EOF
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: grafana-http-route
  namespace: $ns
spec:
  parentRefs:
    - name: $gateway_name
      namespace: $gateway_namespace
      sectionName: shared-http
    - name: $gateway_name
      namespace: $gateway_namespace
      sectionName: shared-https
  hostnames:
    - $domain_grafana
  rules:
    - backendRefs:
        - name: $service_name_grafana
          port: $prome_grafana_port
      timeouts:
        request: 0s
        backendRequest: 0s
EOF

kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: prome-http-route
  namespace: $ns
spec:
  parentRefs:
    - name: $gateway_name
      namespace: $gateway_namespace
      sectionName: shared-http
    - name: $gateway_name
      namespace: $gateway_namespace
      sectionName: shared-https
  hostnames:
    - $domain_prome
  rules:
    - backendRefs:
        - name: $service_name_prome
          port: $prome_grafana_port
      timeouts:
        request: 0s
        backendRequest: 0s
EOF

kubectl get secret --namespace monitoring -l app.kubernetes.io/component=admin-secret -o jsonpath="{.items[0].data.admin-password}" | base64 --decode  > "$currDir/grafana_pwd"