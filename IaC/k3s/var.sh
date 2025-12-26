#!/bin/bash
set -eo pipefail
envrcChangeme="$(dirname $(dirname $(pwd)))/.envrc_changeme"
envrc="$(dirname $(dirname $(pwd)))/.envrc"
k3sAnsiblePath="k3sAnsible/"
k3sPath="$(pwd)"
allYmlPath=${k3sAnsiblePath}inventory/my-cluster/group_vars/all.yml
hostsPath=${k3sAnsiblePath}inventory/my-cluster/hosts.ini
kubeConfigPath="$(pwd)/k3s.yaml"
scaling_inventory="scaling_inventory.yml"
site_inventory="site_inventory.yml"
reset_path=playbooks/reset.yml