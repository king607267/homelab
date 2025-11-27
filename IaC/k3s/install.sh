#!/bin/bash
set -eo pipefail
envrcChangeme="$(dirname $(dirname $(pwd)))/.envrc_changeme"
envrc="$(dirname $(dirname $(pwd)))/.envrc"
k3sAnsiblePath="k3sAnsible/"
vmsPath="$( dirname $(pwd))/vms/"
k3sPath="$(pwd)"
allYmlPath=${k3sAnsiblePath}inventory/my-cluster/group_vars/all.yml
hostsPath=${k3sAnsiblePath}inventory/my-cluster/hosts.ini
kubeConfigPath="$(pwd)/k3s.yaml"

if ! command -v direnv &> /dev/null; then
    echo "Please install direnv https://github.com/direnv/direnv/blob/master/docs/installation.md"
    echo "hook into your shell. https://github.com/direnv/direnv/blob/master/docs/hook.md#setup"
    echo "sudo apt update && sudo apt install direnv && echo 'eval \"\$(direnv hook bash)\"' >> ~/.bashrc && source ~/.bashrc"
    exit 1
fi

if ! command -v ansible &> /dev/null; then
  echo "Please install ansible2.11+, https://technotim.live/posts/ansible-automation/#installing-the-latest-version-of-ansible"
  echo "curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3 get-pip.py && python3 -m pip -V && echo 'export PATH=\"/home/`whoami`/.local/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc && python3 -m pip install netaddr && python3 -m pip install --user ansible"
  echo "or"
  echo "sudo apt install ansible"
  exit 1
fi

if [ -f "$envrcChangeme" ]; then
  echo "Please edit .envrc_changeme and change the values to your own. rename to .envrc  run again"
  echo "nano $envrcChangeme && mv $envrcChangeme $envrc"
  exit 1
fi

if [ -n "$install_vms" ]; then
  cd "$vmsPath"
  ./install.sh
  cd "$k3sPath"
fi

if [ ! -d "$k3sAnsiblePath" ]; then
  git clone https://github.com/king607267/k3s-ansible.git ${k3sAnsiblePath}
else
  git -C ${k3sAnsiblePath} pull
fi

ansible-galaxy collection install -r ${k3sAnsiblePath}collections/requirements.yml

if [ ! -f "all_changeme.yml" ]; then
  cp -af ${k3sAnsiblePath}inventory/sample/group_vars/all.yml all_changeme.yml
  echo "Please edit all_changeme.yml,.envrc and change the values to your own. run again"
  echo "nano all_changeme.yml"
  exit 0
fi

cp -af ${k3sAnsiblePath}inventory/sample ${k3sAnsiblePath}inventory/my-cluster
cp -af all_changeme.yml  $allYmlPath

echo "[master]" > "${hostsPath}"
for ip in $TF_VAR_master_ips; do
  echo "$ip"  | sed 's/[][]//g; s/"//g; s/,/\n/g' >> "${hostsPath}"
done
echo "" >> "${hostsPath}"
echo "[node]" >> "${hostsPath}"
for ip in $TF_VAR_node_ips; do
  echo "$ip"  | sed 's/[][]//g; s/"//g; s/,/\n/g' >> "${hostsPath}"
done

echo "" >> "${hostsPath}"
echo "[k3s_cluster:children]" >> "${hostsPath}"
echo "master" >> "${hostsPath}"
echo "node" >> "${hostsPath}"

cp -af ${k3sAnsiblePath}ansible.example.cfg  ${k3sAnsiblePath}ansible.cfg
ansible-playbook ${k3sAnsiblePath}site.yml -i $hostsPath

for ip in $TF_VAR_master_ips; do
  ssh -o LogLevel=FATAL -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "${TF_VAR_user}"@$(echo $ip | sed 's/[][]//g; s/"//g; s/,//g') 'sudo cat /etc/rancher/k3s/k3s.yaml' > ./k3s.yaml
  break
done
if [ -f "$kubeConfigPath" ]; then
  sed -i "s|127.0.0.1|$(cat $allYmlPath | grep apiserver_endpoint: | awk '{print $2}')|" $kubeConfigPath
fi