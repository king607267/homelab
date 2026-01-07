#!/bin/bash
set -eo pipefail

envrcChangeme="$(dirname $(dirname $(pwd)))/.envrc_changeme"
envrc="$(dirname $(dirname $(pwd)))/.envrc"

if ! command -v direnv &> /dev/null; then
    echo "Please install direnv https://github.com/direnv/direnv/blob/master/docs/installation.md"
    echo "hook into your shell. https://github.com/direnv/direnv/blob/master/docs/hook.md#setup"
    echo "sudo apt update && sudo apt install direnv && echo 'eval \"\$(direnv hook bash)\"' >> ~/.bashrc && source ~/.bashrc"
    exit 1
fi

if ! command -v virsh &> /dev/null; then
    sudo apt update && sudo apt -y install libvirt-clients
fi

if [ -f "$envrcChangeme" ]; then
  echo "Please edit .envrc_changeme and change the values to your own. rename to .envrc  run again"
  echo "nano $envrcChangeme && mv $envrcChangeme $envrc"
  exit 1
fi

if [ -z "$TF_VAR_libvirt" ]; then
  echo "Please change TF_VAR_libvirt in .evnrc."
  echo "https://blog.csdn.net/xiaoyi23000/article/details/80597516#commentBox"
  echo "ssh-keygen -t rsa && ssh-copy-id -i ~/.ssh/id_rsa.pub user@ip"
  echo "qemu:///system or qemu+ssh://@@change@@@ip/system?keyfile=~/.ssh/id_rsa"
  exit 1
fi

if [ -z "$(virsh -c $TF_VAR_libvirt pool-list --all | grep $TF_VAR_volume_pool_name)" ]; then
  echo "sudo mkdir -p $TF_VAR_libvirt_disk_path"
  echo "virsh -c $TF_VAR_libvirt pool-define-as $TF_VAR_volume_pool_name dir - - - -  $TF_VAR_libvirt_disk_path"
  echo "virsh -c $TF_VAR_libvirt pool-start $TF_VAR_volume_pool_name"
  echo "virsh -c $TF_VAR_libvirt pool-autostart $TF_VAR_volume_pool_name"
  exit 1
fi

if [ ! -f "$TF_VAR_cloudimg_path" ]; then
  echo "$TF_VAR_cloudimg_path does not exist."
  echo "sudo mkdir -p $(dirname $TF_VAR_cloudimg_path) && sudo wget https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-${cloudimg_version}-server-cloudimg-amd64.img -O $TF_VAR_cloudimg_path"
  exit 1
fi

if [ -z "$TF_VAR_ssh_authorized_keys" ] || [ "$TF_VAR_ssh_authorized_keys" = "[]" ]; then
  echo "Please change TF_VAR_ssh_authorized_keys in .evnrc."
  echo "cat  ~/.ssh/id_rsa.pub"
  exit 1
fi

if [ -z "$TF_VAR_master_ips" ] || [ "$TF_VAR_master_ips" = "[]" ] || [ -z "$TF_VAR_node_ips" ] || [ "$TF_VAR_node_ipss" = "[]" ] || [ -z "$TF_VAR_def_gateway" ] || [ -z "$TF_VAR_dns_server" ]; then
  echo "Please edit and change TF_VAR_master_ips,TF_VAR_node_ips,TF_VAR_def_gateway,TF_VAR_dns_server"
  exit 1
fi
echo "Please input control node password:"
sudo snap install --classic opentofu
grep -Fxq 'export PATH="/snap/bin:$PATH"' ~/.bashrc || echo 'export PATH="/snap/bin:$PATH"' >> ~/.bashrc
if ! command -v mkisofs &> /dev/null; then
  echo "Please input control node password:"
  sudo apt-get -y update && sudo apt-get -y install mkisofs
fi
tofu init -upgrade
tofu apply --auto-approve