#!/bin/bash
ns="cert-manager"
alidnsSecretName="alidns-secret"

#https://cert-manager.io/docs/configuration/acme/http01/#configuring-the-http-01-gateway-api-solver
#https://cert-manager.io/docs/usage/gateway/
#https://cert-manager.io/docs/troubleshooting/
helm repo add jetstack https://charts.jetstack.io
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace \
  --wait --timeout=300s \
  --set crds.enabled=true \
  --set featureGates=ExperimentalGatewayAPISupport=true \
  --set "extraArgs={--enable-gateway-api}"

#https://github.com/wjiec/alidns-webhook
#https://github.com/DEVmachine-fr/cert-manager-alidns-webhook
helm repo add cert-manager-alidns-webhook https://devmachine-fr.github.io/cert-manager-alidns-webhook
helm upgrade --install alidns-webhook cert-manager-alidns-webhook/alidns-webhook \
  --namespace cert-manager \
  --wait --timeout=300s \
  --set nodeSelector."kubernetes\\.io/arch"=amd64 \
  --atomic

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $alidnsSecretName
  namespace: cert-manager
data:
  access-key: $alidns_access_key
  secret-key: $alidns_secret_key
EOF

kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: cert-manager
spec:
  acme:
    email: $alidns_acme_email
    server: $alidns_issuer_server
    privateKeySecretRef:
      name: letsencrypt
    solvers:
      - dns01:
          webhook:
            config:
              accessTokenSecretRef:
                key: access-key
                name: $alidnsSecretName
              regionId: $alidns_region_id
              secretKeySecretRef:
                key: secret-key
                name: $alidnsSecretName
            groupName: $alidns_group_name
            solverName: alidns-solver
EOF
#kubectl wait --for=condition=Ready certificate --all -n $cert-manager --timeout=300s