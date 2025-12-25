#!/bin/bash
#https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/
#https://pvital.wordpress.com/2015/09/18/nested-virtualization-and-the-network-issue/
ns="dsm"
currDir="$(dirname "$0")"
workDir="chart_$ns"
gitRpo="https://github.com/king607267/virtual-dsm.git"
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

helm upgrade --install dsm "$currDir/$workDir/helm/virtual-dsm" -n "$ns" -f - <<EOF
securityContext:
  capabilities:
    add:
      - NET_ADMIN

service:
  ports:
    - name: http
      port: "$vdsm_http_port"
      protocol: TCP
      targetPort: "$vdsm_http_port"
    - name: https
      port: "$vdsm_https_port"
      protocol: TCP
      targetPort: "$vdsm_https_port"
    - name: ssh
      port: "$vdsm_ssh_port"
      protocol: TCP
      targetPort: 22

routes:
- name: http
  port: "$vdsm_http_port"
  protocol: http
  hostName: "$domain_nas"
- name: https
  port: "$vdsm_https_port"
  protocol: https
  hostName: "$domain_nas"
- name: tcp
  port: "$vdsm_ssh_port"
  protocol: tcp

resources:
    requests:
      cpu: 1
      memory: 2Gi
    limits:
      cpu: 1
      memory: 2Gi

volumes:
  - name: storage1
    diskSize: 20G
    diskFormat: qcow2
    hostPath:
      path: /mnt/storage/dsm
      type: DirectoryOrCreate

volumeMounts:
  - name: storage1
    mountPath: /storage

nodeSelector:
  kubernetes.io/hostname: host0
EOF