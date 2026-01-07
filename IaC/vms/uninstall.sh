#!/bin/bash
set -eo pipefail
tofu destroy --auto-approve
echo "To delete the storage pool, please execute:"
echo "virsh -c $TF_VAR_libvirt pool-destroy $TF_VAR_volume_pool_name"
echo "virsh -c $TF_VAR_libvirt pool-delete --pool $TF_VAR_volume_pool_name"
echo "virsh -c $TF_VAR_libvirt pool-undefine $TF_VAR_volume_pool_name"