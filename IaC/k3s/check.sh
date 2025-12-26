#!/bin/bash
set -eo pipefail
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