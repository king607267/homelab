#https://blog.ruanbekker.com/blog/2020/10/08/using-the-libvirt-provisioner-with-terraform-for-kvm/
#https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs
provider "libvirt" {
  uri = var.libvirt
}

resource "libvirt_pool" "ubuntu" {
  name = "homelab"
  type = "dir"
  target {
    path = var.libvirt_disk_path
  }
}

resource "libvirt_volume" "ubuntu-qcow2" {
  name   = format("%s-cloudimg$%d", var.hostname_prefix, count.index)
  pool   = libvirt_pool.ubuntu.name
  source = var.cloudimg_url
  format = "qcow2"
  count  = length(concat(var.master_ips, var.node_ips))
}

resource "libvirt_volume" "disk_ubuntu_resized" {
  name           = "${var.hostname_prefix}${count.index}"
  base_volume_id = element(libvirt_volume.ubuntu-qcow2.*.id, count.index)
  pool           = libvirt_pool.ubuntu.name
  size           = var.disk_size
  count          = length(concat(var.master_ips, var.node_ips))
}

resource "libvirt_volume" "disk_ubuntu_resized_data" {
  name  = format("%s-data%d", var.hostname_prefix, count.index)
  pool  = libvirt_pool.ubuntu.name
  size  = var.data_disk_size
  count = length(concat(var.master_ips, var.node_ips))
}

#https://yping88.medium.com/provisioning-multiple-linux-distributions-using-terraform-provider-for-libvirt-632186f1c007
resource "libvirt_cloudinit_disk" "commoninit" {
  count          = length(concat(var.master_ips, var.node_ips))
  name           = format("%s-commoninit%d.iso", var.hostname_prefix, count.index)
  user_data      = data.template_file.user_data[count.index].rendered
  network_config = data.template_file.network_config[count.index].rendered
  pool           = libvirt_pool.ubuntu.name
}

data "template_file" "user_data" {
  count    = length(concat(var.master_ips, var.node_ips))
  template = file("${path.module}/config/cloud_init.yml")
  vars     = {
    host_name           = "${var.hostname_prefix}${count.index}"
    user                = var.user
    passwd              = var.passwd
    ssh_authorized_keys = var.ssh_authorized_keys
    proxy_ip            = var.proxy_ip
    no_proxy_ip         = var.no_proxy_ip
  }
}

data "template_file" "network_config" {
  count    = length(concat(var.master_ips, var.node_ips))
  template = file("${path.module}/config/network_config.yml")
  vars     = {
    ip_addr     = concat(var.master_ips, var.node_ips)[count.index]
    dns_server  = var.dns_server
    def_gateway = var.def_gateway
  }
}

resource "libvirt_domain" "domain-ubuntu" {
  name      = "${var.hostname_prefix}${count.index}"
  memory    = var.memory
  vcpu      = var.vcpu
  cloudinit = element(libvirt_cloudinit_disk.commoninit.*.id, count.index)
  count     = length(concat(var.master_ips, var.node_ips))

  network_interface {
    bridge         = "br0"
    wait_for_lease = false
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.disk_ubuntu_resized[count.index].id
  }

  disk {
    volume_id = libvirt_volume.disk_ubuntu_resized_data[count.index].id
  }

  graphics {
    type           = "spice"
    listen_type    = "address"
    listen_address = "0.0.0.0"
    autoport       = true
  }

  provisioner "remote-exec" {
    inline = [
      "echo hostname:`cat /etc/hostname`",
      #      "echo '${LOCAL_IP-:`ip addr | sed -En \'s/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p\'`}'"
    ]

    connection {
      type        = "ssh"
      user        = var.user
      host        = concat(var.master_ips, var.node_ips)[count.index]
      #                host        = libvirt_domain.domain-ubuntu[0].network_interface[0].addresses[0]
      private_key = file(var.ssh_private_key)
      #      bastion_host        = "ams-kvm-remote-host"
      #      bastion_user        = "deploys"
      #      bastion_private_key = file("~/.ssh/deploys.pem")
      timeout     = "2m"
    }
  }

}