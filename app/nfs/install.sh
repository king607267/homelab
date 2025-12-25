#!/bin/bash
ns="nfs"
currDir="$(dirname "$0")"
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
helm upgrade --install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
     -n nfs --create-namespace \
     --set nfs.server="$nfs_server" \
     --set nfs.path="$nfs_server_path" \
     --set storageClass.defaultClass=true