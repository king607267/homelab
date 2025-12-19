#!/bin/bash
set -e
echo "Provisioning started"
apt update && apt install -y vi nfs-common
echo "Provisioning complete"