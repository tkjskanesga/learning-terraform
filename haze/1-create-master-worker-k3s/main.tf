(* Otomasi pembuatan k3s master dan worker ke node yang sudah ada *)

# node master
variable "master_user" {
  default = "lks1" # Username VM Master
}

variable "master_ip" {
  default = "192.168.100.121" # IP VM Master Anda
}

# node worker
variable "worker_user" {
  default = "lks2" # Username untuk VM Worker berbeda
}

variable "worker_ip" {
  default = "192.168.100.122" # IP VM Worker
}

variable "ssh_private_key_path" {
  default = "~/.ssh/id_rsa" # SSH Key local
}

# Node Master
resource "null_resource" "k3s_master" {
  connection {
    type        = "ssh"
    user        = var.master_user 
    private_key = file(var.ssh_private_key_path)
    host        = var.master_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sh -c 'echo \"nameserver 8.8.8.8\" > /etc/resolv.conf'",
      "echo 'lks1' | sudo -S curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=\"v1.31.1+k3s1\" sh -",
      "sleep 10", 
      "echo 'lks1' | sudo -S sudo cat /var/lib/rancher/k3s/server/node-token"
    ]
  }
}

# 5. Token K3s dari Master
data "external" "k3s_token" {
  depends_on = [null_resource.k3s_master]
  program = ["ssh", "-o", "StrictHostKeyChecking=no", "-i", var.ssh_private_key_path, "${var.master_user}@${var.master_ip}", "sudo cat /var/lib/rancher/k3s/server/node-token | jq -R '{token: .}'"]
}

# Node Worker
resource "null_resource" "k3s_worker" {
  depends_on = [null_resource.k3s_master]

  connection {
    type        = "ssh"
    user        = var.worker_user 
    private_key = file(var.ssh_private_key_path)
    host        = var.worker_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sh -c 'echo \"nameserver 8.8.8.8\" > /etc/resolv.conf'",
      "echo 'lks2' | sudo -S curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=\"v1.31.1+k3s1\" K3S_URL=https://${var.master_ip}:6443 K3S_TOKEN=${data.external.k3s_token.result.token} sh -"
    ]
  }
}
