# Init Providers: https://registry.terraform.io/providers/Telmate/proxmox/latest/docs/guides/installation
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

# Declaration Variable
variable "pm_api_url" {
  type = string
  default = "https://172.18.20.2:8006/api2/json"
}
variable "pm_default" { type = string }
variable "pm_user" {
  type = string
  default = "root@pam"
}
variable "pm_password" {
  type = string
  default = "admin#1234"
}
variable "pm_tls_insecure" {
  type = bool
  default = true
}
variable "lxc_sshkey" {
  type = string
  default = ""
}
variable "lxc_id_start_from" {
  type = number
  default = 200 # Start ID From 200
}
variable "lxc_total_duplicate" {
  type = number
  default = 3
}

# Proxmox Configuration
provider "proxmox" {
  pm_api_url = var.pm_api_url
  pm_user = var.pm_user
  pm_password = var.pm_password
  pm_tls_insecure = var.pm_tls_insecure
}

# LXC Create Multiple: https://registry.terraform.io/providers/Telmate/proxmox/latest/docs/resources/lxc
resource "proxmox_lxc" "basic" {
  count        = var.lxc_total_duplicate
  target_node  = var.pm_default
  vmid         = var.lxc_id_start_from + count.index
  hostname     = "node-lxc-${var.lxc_id_start_from + count.index}"
  ostemplate   = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  password     = "HIDUPJOKOWI@26"
  unprivileged = true

  # SSH Public Key
  ssh_public_keys = var.lxc_sshkey

  # Tag Label
  tags = "terraform;learning;vlan-30"

  # Spec
  cores  = 2
  memory = 2048

  # Storage
  rootfs {
    storage = "local-lvm"
    size    = "12G"
  }

  # Network
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "192.168.31.${150 + count.index}/23"
    gw     = "192.168.30.1"
    tag    = 30 # VLAN 30
  }
}