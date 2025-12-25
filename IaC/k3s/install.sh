#!/bin/bash
set -eo pipefail
envrcChangeme="$(dirname $(dirname $(pwd)))/.envrc_changeme"
envrc="$(dirname $(dirname $(pwd)))/.envrc"
k3sAnsiblePath="k3sAnsible/"
k3sPath="$(pwd)"
allYmlPath=${k3sAnsiblePath}inventory/my-cluster/group_vars/all.yml
hostsPath=${k3sAnsiblePath}inventory/my-cluster/hosts.ini
kubeConfigPath="$(pwd)/k3s.yaml"
#
if ! command -v direnv &> /dev/null; then
    echo "Please install direnv https://github.com/direnv/direnv/blob/master/docs/installation.md"
    echo "hook into your shell. https://github.com/direnv/direnv/blob/master/docs/hook.md#setup"
    echo "sudo apt update && sudo apt install direnv && echo 'eval \"\$(direnv hook bash)\"' >> ~/.bashrc && source ~/.bashrc"
    exit 1
fi

if [ -f "$envrcChangeme" ]; then
  echo "Please edit .envrc_changeme and change the values to your own. rename to .envrc  run again"
  echo "nano $envrcChangeme && mv $envrcChangeme $envrc"
  exit 1
fi

if ! command -v ansible &> /dev/null; then
  echo "Please install ansible2.11+, https://technotim.live/posts/ansible-automation/#installing-the-latest-version-of-ansible"
  echo "curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3 get-pip.py && python3 -m pip -V && echo 'export PATH=\"/home/`whoami`/.local/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc && python3 -m pip install netaddr && python3 -m pip install --user ansible"
  echo "or"
  echo "sudo apt install ansible"
  exit 1
fi


if [ ! -d "$k3sAnsiblePath" ]; then
  git clone https://github.com/king607267/k3sAnsible.git ${k3sAnsiblePath}
else
  git -C ${k3sAnsiblePath} pull
fi

ansible-galaxy collection install -r ${k3sAnsiblePath}collections/requirements.yml

if [ ! -f "inventory.yml" ]; then
  echo "---" >> inventory.yml
  echo "k3s_cluster:" >> inventory.yml
  echo "  children:" >> inventory.yml
  echo "    server:" >> inventory.yml
  echo "      hosts:" >> inventory.yml
  echo "        $TF_VAR_master_ips" | sed 's/[][]//g; s/"//g; s/,/:\n        /g; s/$/:/' >> inventory.yml
  echo "    agent:" >> inventory.yml
  echo "      hosts:" >> inventory.yml
  echo "        $TF_VAR_node_ips" | sed 's/[][]//g; s/"//g; s/,/:\n        /g; s/$/:/' >> inventory.yml
  grep -A 100 "vars:" ${k3sAnsiblePath}inventory-sample.yml >> inventory.yml
  sed -i "s/ansible_user:.*$/ansible_user: $TF_VAR_user/g" inventory.yml
fi
echo "Please edit inventory.yml and change the values to your own."
read -p "Press Enter to start editing..."
${EDITOR:-nano} "inventory.yml"
cp -af inventory.yml ${k3sAnsiblePath}inventory.yml
cd "$k3sAnsiblePath"
ansible-playbook playbooks/site.yml -i inventory.yml
cd "$k3sPath"

master_ip=$(echo "$TF_VAR_master_ips" | sed 's/[][]//g; s/"//g;'| awk -F',' '{print $1}')
ssh -o LogLevel=FATAL -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "${TF_VAR_user}"@"$master_ip" 'sudo cat /etc/rancher/k3s/k3s.yaml' > "$kubeConfigPath"
if [ -f "$kubeConfigPath" ]; then
  sed -i "s|127.0.0.1|$master_ip|" "$kubeConfigPath"
fi

if ! command -v kubectl &> /dev/null; then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  chmod +x kubectl
  mkdir -p ~/.local/bin
  mv ./kubectl ~/.local/bin/kubectl
fi
kubectl get nodes;