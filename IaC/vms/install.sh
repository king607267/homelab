#!/bin/bash
set -eo pipefail
if [ ! -e $(dirname "$TF_VAR_libvirt_disk_path") ]; then
  echo "$(dirname "$TF_VAR_libvirt_disk_path") does not exist."
  echo "sudo mkdir -p $(dirname $TF_VAR_libvirt_disk_path)"
  exit 1
fi
if [ ! -f "$TF_VAR_cloudimg_url" ]; then
  echo "$TF_VAR_cloudimg_url does not exist."
  echo "sudo mkdir -p $(dirname $TF_VAR_cloudimg_url) && sudo wget https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-amd64.img -O $TF_VAR_cloudimg_url"
  exit 1
fi
if [ "$TF_VAR_libvirt" = "" ]; then
  echo "Please change TF_VAR_libvirt in .evnrc."
  echo "https://blog.csdn.net/xiaoyi23000/article/details/80597516#commentBox"
  echo "ssh-keygen -t rsa && ssh-copy-id -i ~/.ssh/id_rsa.pub user@ip"
  echo "qemu:///system or qemu+ssh://@@change@@ip/system?keyfile=~/.ssh/id_rsa "
  exit 1
fi

if [ -z "$TF_VAR_ssh_authorized_keys" ] || [ "$TF_VAR_ssh_authorized_keys" = "[]" ]; then
  echo "Please change TF_VAR_ssh_authorized_keys in .evnrc."
  echo "ssh-keygen -t rsa"
  echo "cat  ~/.ssh/id_rsa.pub"
  exit 1
fi

if [ -z "$TF_VAR_master_ips" ] || [ "$TF_VAR_master_ips" = "[]" ] || [ -z "$TF_VAR_node_ips" ] || [ "$TF_VAR_node_ipss" = "[]" ] || [ -z "$TF_VAR_def_gateway" ] || [ -z "$TF_VAR_dns_server" ]; then
  echo "Please edit and change TF_VAR_master_ips,TF_VAR_node_ips,TF_VAR_def_gateway,TF_VAR_dns_server"
  exit 1
fi
echo "Please input control node password:"
sudo snap install --classic opentofu
echo "export PATH="/snap/bin:\$PATH\" >> ~/.bashrc && source ~/.bashrc
if ! command -v mkisofs &> /dev/null; then
  echo "Please input control node password:"
  sudo apt-get -y update && sudo apt-get -y install mkisofs
fi
tofu init
tofu destroy --auto-approve
tofu apply --auto-approve