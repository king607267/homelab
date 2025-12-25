#!/bin/bash
#https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/
ns="wow"
currDir="$(dirname "$0")"
workDir="chart_$ns"
gitRpo="https://github.com/king607267/cmangos-wrapper.git"
if [ ! -d "$currDir/$workDir" ]; then
  git clone $gitRpo "$currDir/$workDir"
else
  git -C "$currDir/$workDir" pull
fi

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $ns
  labels:
    shared-gateway-access: "true"
EOF

helm upgrade --install classic "$currDir/$workDir/k8s/helm/cmangos" -n "$ns" \
-f - <<EOF
cmangos:
  type: classic

realmd:
  nodeSelector: "kubernetes.io/arch: amd64"
  service:
    type: ClusterIP

server:
  nodeSelector: "kubernetes.io/arch: amd64"
  tagName: latest
  service:
    type: ClusterIP
  resources:
    limits:
      cpu: 1
      memory: 1024Mi

mysql:
  enabled: false
  changeIpJob:
    enabled: false
  externalName: $wow_mysql_external_name
  customSqlURL: $wow_custom_sql_url
  realm:
    ip: 127.0.0.1
    name: $wow_classic_realm_name
    port: $wow_classic_realm_port
  nodeSelector: "kubernetes.io/hostname: host0"
  service:
    type: ClusterIP
  user: $wow_classic_mysql_user_name
  password: $wow_classic_mysql_user_pwd
  rootPassword: $wow_classic_mysql_user_root_pwd
  port: $wow_classic_mysql_user_port
  tz: $wow_classic_mysql_user_tz
  i18n: $wow_classic_mysql_user_i18n
  resources:
    limits:
      cpu: 0.5
      memory: 750Mi

image:
  pullPolicy: Always

registration:
  tagName: latest
  nodeSelector: "kubernetes.io/arch: amd64"
  service:
    type: ClusterIP
  tls:
    enabled: false
  expansion: 0 #0 classic,1 tbc,2 wotlk

gateway:
  registration:
    domain: $domain_wow_classic
    port: $wow_classic_registration_http_port
    tls:
      enabled: false
      port: wow_classic_registration_https_port

nfs:
  server: $wow_maps_nfs_ser
  path: $wow_maps_nfs_path
EOF


helm upgrade --install tbc "$currDir/$workDir/k8s/helm/cmangos" -n "$ns" \
-f - <<EOF
cmangos:
  type: tbc

realmd:
  nodeSelector: "kubernetes.io/arch: amd64"
  service:
    type: ClusterIP

server:
  nodeSelector: "kubernetes.io/arch: amd64"
  service:
    type: ClusterIP
  resources:
    limits:
      cpu: 1
      memory: 1280Mi

mysql:
  enabled: false
  changeIpJob:
    enabled: false
  externalName: $wow_mysql_external_name
  customSqlURL: $wow_custom_sql_url
  realm:
    ip: 127.0.0.1
    name: $wow_tbc_realm_name
    port: $wow_tbc_realm_port
  nodeSelector: "kubernetes.io/hostname: host0"
  service:
    type: ClusterIP
  user: $wow_tbc_mysql_user_name
  password: $wow_tbc_mysql_user_pwd
  rootPassword: $wow_tbc_mysql_user_root_pwd
  port: $wow_tbc_mysql_user_port
  tz: $wow_tbc_mysql_user_tz
  i18n: $wow_tbc_mysql_user_i18n
  resources:
    limits:
      cpu: 0.5
      memory: 750Mi

image:
  pullPolicy: Always

registration:
  tagName: latest
  nodeSelector: "kubernetes.io/arch: amd64"
  service:
    type: ClusterIP
  tls:
    enabled: false
  expansion: 1 #0 classic,1 tbc,2 wotlk

gateway:
  registration:
    domain: $domain_wow_tbc
    port: $wow_tbc_registration_http_port
    tls:
      enabled: false
      port: wow_tbc_registration_https_port

nfs:
  server: $wow_maps_nfs_ser
  path: $wow_maps_nfs_path
EOF

helm upgrade --install wotlk "$currDir/$workDir/k8s/helm/cmangos" -n "$ns" \
-f - <<EOF
cmangos:
  type: wotlk

realmd:
  nodeSelector: "kubernetes.io/arch: amd64"
  service:
    type: ClusterIP

server:
  nodeSelector: "kubernetes.io/arch: amd64"
  service:
    type: ClusterIP
  resources:
    limits:
      cpu: 1
      memory: 1280Mi

mysql:
  enabled: false
  changeIpJob:
    enabled: false
  externalName: $wow_mysql_external_name
  customSqlURL: $wow_custom_sql_url
  realm:
    ip: 127.0.0.1
    name: $wow_wotlk_realm_name
    port: $wow_wotlk_realm_port
  nodeSelector: "kubernetes.io/hostname: host0"
  service:
    type: ClusterIP
  user: $wow_wotlk_mysql_user_name
  password: $wow_wotlk_mysql_user_pwd
  rootPassword: $wow_wotlk_mysql_user_root_pwd
  port: $wow_wotlk_mysql_user_port
  tz: $wow_wotlk_mysql_user_tz
  i18n: $wow_wotlk_mysql_user_i18n
  resources:
    limits:
      cpu: 1
      memory: 900Mi

image:
  pullPolicy: Always

registration:
  tagName: latest
  nodeSelector: "kubernetes.io/arch: amd64"
  service:
    type: ClusterIP
  tls:
    enabled: false
  expansion: 1 #0 classic,1 tbc,2 wotlk

gateway:
  registration:
    domain: $domain_wow_wotlk
    port: $wow_wotlk_registration_http_port
    tls:
      enabled: false
      port: wow_wotlk_registration_https_port

nfs:
  server: $wow_maps_nfs_ser
  path: $wow_maps_nfs_path
EOF