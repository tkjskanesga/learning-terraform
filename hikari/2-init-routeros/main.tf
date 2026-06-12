# Init Providers: https://registry.terraform.io/providers/terraform-routeros/routeros/latest/docs
terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
      version = "1.99.0"
    }
  }
}

# Init RouterOS
provider "routeros" {
  alias    = "r1"
  hosturl  = "http://127.0.0.1:4002"
  username = "admin"
  password = ""
}
provider "routeros" {
  alias    = "r2"
  hosturl  = "http://127.0.0.1:4102"
  username = "admin"
  password = ""
}
provider "routeros" {
  alias    = "r3"
  hosturl  = "http://127.0.0.1:4202"
  username = "admin"
  password = ""
}

# Setup Identity
resource "routeros_system_identity" "r1" {
  provider = routeros.r1
  name     = "R1-Core"
}
resource "routeros_system_identity" "r2" {
  provider = routeros.r2
  name     = "R2-Bridge"
}
resource "routeros_system_identity" "r3" {
  provider = routeros.r3
  name     = "R3-PrivateLink"
}

# Adding IP
resource "routeros_ip_address" "r1_to_r2" {
  provider  = routeros.r1
  address   = "172.20.0.1/28"
  interface = "ether2" # R1 > R2
  network   = "172.20.0.0"
}
resource "routeros_ip_address" "r2_to_r1" {
  provider  = routeros.r2
  address   = "172.20.0.2/28"
  interface = "ether2" # R2 > R1
  network   = "172.20.0.0"
}
resource "routeros_ip_address" "r2_to_r3" {
  provider  = routeros.r2
  address   = "172.20.1.1/28"
  interface = "ether3" # R2 > R3
  network   = "172.20.1.0"
}
resource "routeros_ip_address" "r3_to_r2" {
  provider  = routeros.r3
  address   = "172.20.1.2/28"
  interface = "ether2" # R3 > R2
  network   = "172.20.1.0"
}

# Routing
resource "routeros_ip_route" "r1_pointing_r3" {
  provider    = routeros.r1
  dst_address = "172.20.1.0/28"
  gateway     = "172.20.0.2"
}
resource "routeros_ip_route" "r3_pointing_r1" {
  provider    = routeros.r3
  dst_address = "172.20.0.0/28"
  gateway     = "172.20.1.1"
}