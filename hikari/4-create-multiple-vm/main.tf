terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

variable "pm_api_url" {
  type    = string
  default = "https://172.18.20.2:8006/api2/json"
}
variable "pm_default" { type = string }
variable "pm_user" {
  type    = string
  default = "root@pam"
}
variable "pm_password" {
  type    = string
  default = "admin#1234"
}
variable "pm_tls_insecure" {
  type    = bool
  default = true
}

variable "vm_id_start_from" {
  type    = number
  default = 300
}
variable "vm_total_duplicate" {
  type    = number
  default = 3
}
variable "vm_template_name" {
  type    = string
  default = "ubuntu-2204-cloudimage"
}
variable "vm_cpu_cores" {
  type    = number
  default = 2
}
variable "vm_memory" {
  type    = number
  default = 2048
}
variable "vm_disk_size" {
  type    = string
  default = "20G"
}
variable "vm_storage" {
  type    = string
  default = "local-lvm"
}
variable "vm_ip_start" {
  type    = number
  default = 150
}
variable "vm_ci_user" {
  type    = string
  default = "ubuntu"
}
variable "vm_ci_password" {
  type    = string
  default = "ubuntu"
}
variable "vm_bridge" {
  type    = string
  default = "vmbr0"
}
variable "vm_subnet" {
  type    = string
  default = "192.168.30"
}
variable "vm_gateway" {
  type    = string
  default = "192.168.30.1"
}
variable "vm_cidr" {
  type    = string
  default = "/23"
}
variable "vm_vlan_tag" {
  type    = number
  default = 30
}

provider "proxmox" {
  pm_api_url     = var.pm_api_url
  pm_user        = var.pm_user
  pm_password    = var.pm_password
  pm_tls_insecure = var.pm_tls_insecure
}

resource "proxmox_vm_qemu" "cloud" {
  count       = var.vm_total_duplicate
  target_node = var.pm_default
  vmid        = var.vm_id_start_from + count.index
  name        = "vm-cloud-${var.vm_id_start_from + count.index}"
  clone       = var.vm_template_name
  full_clone  = true
  agent       = 1
  os_type     = "cloud-init"
  memory      = var.vm_memory

  cpu {
    cores = var.vm_cpu_cores
    type  = "host"
  }

  scsihw      = "virtio-scsi-pci"
  boot        = "order=scsi0"

  tags        = "terraform;cloud-init;vlan-${var.vm_vlan_tag}"

  disks {
    ide {
      ide2 {
        cloudinit {
          storage = var.vm_storage
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          storage = var.vm_storage
          size    = var.vm_disk_size
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = var.vm_bridge
    tag    = var.vm_vlan_tag
  }

  ipconfig0 = "ip=${var.vm_subnet}.${var.vm_ip_start + count.index}${var.vm_cidr},gw=${var.vm_gateway}"

  ciuser     = var.vm_ci_user
  cipassword = var.vm_ci_password

  sshkeys = file("./id_rsa.pub")
}
