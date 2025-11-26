#!/bin/bash
set -e
echo "Provisioning started"
apt update && apt install -y vi
echo "Provisioning complete"