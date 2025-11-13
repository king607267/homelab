variable "libvirt_disk_path" {
  description = "path for libvirt pool"
  #  Permission denied see
  #  https://github.com/dmacvicar/terraform-provider-libvirt/issues/978
  #  https://bugs.launchpad.net/ubuntu/+source/libvirt/+bug/1677398/comments/43
  default     = ""
}

variable "cloudimg_url" {
  description = "OS image"
  default     = ""
}

variable "ssh_private_key" {
  description = "the private key to use"
  default     = "~/.ssh/id_rsa"
}

variable "master_ips" {
  type    = list(string)
  default = []
}

variable "node_ips" {
  type    = list(string)
  default = []
}

variable "def_gateway" {
  type = string
}

variable "dns_server" {
  type = string
}

variable "libvirt" {
  type    = string
  default = "qemu:///system"
}

variable "disk_size" {
  type    = number
  default = 53687091200
}

variable "data_disk_size" {
  type    = number
  default = 53687091200
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "vcpu" {
  type    = number
  default = 1
}

variable "hostname_prefix" {
  type    = string
  default = "terraform-kvm-"
}

variable "user" {
  type    = string
  default = "ubuntu"
}

variable "proxy_ip" {
  type    = string
  default = "localhost"
}
variable "no_proxy_ip" {
  type    = string
  default = "localhost"
}

variable "ssh_authorized_keys" {
  type    = string
  default = ""
}

variable "passwd" {
  type    = string
  default = ""
}