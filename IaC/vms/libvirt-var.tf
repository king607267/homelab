variable "libvirt" {
  type = string
}

variable "libvirt_disk_path" {
  type = string
}

variable "cloudimg_url" {
  type = string
}

variable "memory" {
  type = string
}

variable "vcpu" {
  type = number
}

variable "disk_size" {
  type = number
}

variable "data_disk_size" {
  type = number
}

variable "proxy_ip" {
  type    = string
  default = ""
}
variable "no_proxy_ip" {
  type    = string
  default = ""
}

variable "def_gateway" {
  type = string
}

variable "dns_server" {
  type = string
}

variable "ssh_authorized_keys" {
  type = string
}

variable "passwd" {
  type = string
}

variable "hostname_prefix" {
  type = string
}

variable "user" {
  type = string
}

variable "master_ips" {
  type = list(string)
}

variable "node_ips" {
  type = list(string)
}