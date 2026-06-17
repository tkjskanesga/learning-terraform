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
  default = null
}

provider "proxmox" {
  pm_api_url     = var.pm_api_url
  pm_user        = var.pm_user
  pm_password    = var.pm_password
  pm_tls_insecure = var.pm_tls_insecure
}

locals {
  proxmox_host = split(":", split("/", split("://", var.pm_api_url)[1])[0])[0]
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

  tags        = var.vm_vlan_tag != null ? "terraform;cloud-init;vlan-${var.vm_vlan_tag}" : "terraform;cloud-init"

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
  sshkeys    = try(file("${path.module}/id_rsa.pub"), "")
}

resource "null_resource" "enable_password_auth" {
  count = var.vm_total_duplicate

  depends_on = [proxmox_vm_qemu.cloud]

  triggers = {
    vmid = var.vm_id_start_from + count.index
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command = <<-POWERSHELL
      $login = curl.exe -k -s -X POST "https://${local.proxmox_host}:8006/api2/json/access/ticket" -d "username=${var.pm_user}&password=${var.pm_password}"
      $data = $login | ConvertFrom-Json
      $ticket = [uri]::EscapeDataString($data.data.ticket)
      $token = $data.data.CSRFPreventionToken
      $vmid = ${var.vm_id_start_from + count.index}

      Write-Output "Waiting for VM $vmid agent..."
      do {
        Start-Sleep -Seconds 3
        $resp = curl.exe -k -s -b "PVEAuthCookie=$ticket" -H "CSRFPreventionToken: $token" "https://${local.proxmox_host}:8006/api2/json/nodes/${var.pm_default}/qemu/$vmid/agent/ping"
        $ok = try { ($resp | ConvertFrom-Json).data.result -eq 0 } catch { $false }
      } while (-not $ok)

      Write-Output "Enabling PasswordAuthentication on VM $vmid..."
      curl.exe -k -s -b "PVEAuthCookie=$ticket" -H "CSRFPreventionToken: $token" -X POST "https://${local.proxmox_host}:8006/api2/json/nodes/${var.pm_default}/qemu/$vmid/agent/exec" -H "Content-Type: application/json" -d '{"command":"sed","args":["-i","s/.*PasswordAuthentication.*/PasswordAuthentication yes/","/etc/ssh/sshd_config"]}' | Out-Null
      curl.exe -k -s -b "PVEAuthCookie=$ticket" -H "CSRFPreventionToken: $token" -X POST "https://${local.proxmox_host}:8006/api2/json/nodes/${var.pm_default}/qemu/$vmid/agent/exec" -H "Content-Type: application/json" -d '{"command":"systemctl","args":["restart","sshd"]}' | Out-Null
      Write-Output "Done for VM $vmid!"
    POWERSHELL
  }
}
