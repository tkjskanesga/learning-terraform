variable "master_ip" {
  type = string
}

variable "worker_ips" {
  type    = list(string)
  default = []
}

variable "ssh_user" {
  type    = string
  default = "root"
}

variable "ssh_password" {
  type    = string
  default = ""
}

variable "ssh_private_key" {
  type    = string
  default = ""
}

variable "helm_repos" {
  type = list(object({
    name = string
    url  = string
  }))
  default = [
    { name = "bitnami",       url = "https://charts.bitnami.com/bitnami" },
    { name = "ingress-nginx", url = "https://kubernetes.github.io/ingress-nginx" },
    { name = "jetstack",      url = "https://charts.jetstack.io" },
    { name = "prometheus-community", url = "https://prometheus-community.github.io/helm-charts" },
  ]
}

resource "null_resource" "install_k3s_master" {
  connection {
    type        = "ssh"
    host        = var.master_ip
    user        = var.ssh_user
    password    = var.ssh_password
    private_key = try(file(var.ssh_private_key), null)
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE=644 INSTALL_K3S_EXEC='--bind-address ${var.master_ip}' sh -",
    ]
  }
}

resource "null_resource" "install_k3s_worker" {
  count = length(var.worker_ips)

  depends_on = [null_resource.install_k3s_master]

  triggers = {
    worker_ip = var.worker_ips[count.index]
    master_ip = var.master_ip
  }

  connection {
    type        = "ssh"
    host        = var.worker_ips[count.index]
    user        = var.ssh_user
    password    = var.ssh_password
    private_key = try(file(var.ssh_private_key), null)
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | K3S_URL=https://${var.master_ip}:6443 K3S_TOKEN=$(ssh -o StrictHostKeyChecking=no root@${var.master_ip} cat /var/lib/rancher/k3s/server/node-token) sh -",
    ]
  }
}

resource "null_resource" "setup_helm" {
  depends_on = [null_resource.install_k3s_master]

  connection {
    type        = "ssh"
    host        = var.master_ip
    user        = var.ssh_user
    password    = var.ssh_password
    private_key = try(file(var.ssh_private_key), null)
  }

  provisioner "remote-exec" {
    inline = concat([
      "curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3",
      "chmod +x get_helm.sh && ./get_helm.sh && rm get_helm.sh",
      "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml",
    ], [
      for repo in var.helm_repos :
      "helm repo add ${repo.name} ${repo.url} || true"
    ], [
      "helm repo update",
    ])
  }
}

resource "null_resource" "fetch_kubeconfig" {
  depends_on = [null_resource.install_k3s_master]

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no ${var.ssh_user}@${var.master_ip}:/etc/rancher/k3s/k3s.yaml ${path.module}/kubeconfig.yaml && sed -i 's/127.0.0.1/${var.master_ip}/g' ${path.module}/kubeconfig.yaml"
  }
}

output "kubeconfig_path" {
  value = abspath("${path.module}/kubeconfig.yaml")
}

output "master_ip" {
  value = var.master_ip
}

output "worker_ips" {
  value = var.worker_ips
}
