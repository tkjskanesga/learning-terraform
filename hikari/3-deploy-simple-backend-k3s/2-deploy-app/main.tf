terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

variable "kubeconfig_path" {
  type    = string
  default = "../1-setup-k3s/kubeconfig.yaml"
}

variable "app_name" {
  type    = string
  default = "go-hello"
}

variable "app_image" {
  type    = string
  default = "ernestoyoofi/go-hello:latest"
}

variable "app_replicas" {
  type    = number
  default = 2
}

variable "app_port" {
  type    = number
  default = 8080
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.app_name
    namespace = "default"
    labels = {
      app = var.app_name
    }
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        container {
          name  = var.app_name
          image = var.app_image

          port {
            container_port = var.app_port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name      = var.app_name
    namespace = "default"
    labels = {
      app = var.app_name
    }
  }

  spec {
    selector = {
      app = var.app_name
    }

    type = "NodePort"

    port {
      port        = var.app_port
      target_port = var.app_port
      node_port   = 30080
    }
  }
}

output "app_name" {
  value = var.app_name
}

output "service_port" {
  value = 30080
}

output "access_url" {
  value = "http://<node-ip>:30080"
}
