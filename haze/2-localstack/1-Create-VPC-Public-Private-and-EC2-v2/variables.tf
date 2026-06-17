# ==========================================
# VARIABLE DECLARATIONS
# ==========================================

# --- Provider / LocalStack ---
variable "aws_region" {
  description = "AWS region yang digunakan"
  type        = string
  default     = "us-east-1"
}

variable "localstack_endpoint" {
  description = "URL endpoint LocalStack untuk EC2"
  type        = string
  default     = "http://localhost:4566"
}

# --- Project ---
variable "project_name" {
  description = "Nama project, digunakan sebagai suffix pada tag Name"
  type        = string
  default     = "localstack"
}

# --- VPC & Networking ---
variable "vpc_cidr" {
  description = "CIDR block untuk VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block untuk Public Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block untuk Private Subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability Zone yang digunakan untuk subnet"
  type        = string
  default     = "us-east-1a"
}

# --- Security Group ---
variable "ssh_ingress_cidr" {
  description = "CIDR yang diizinkan mengakses port SSH (22)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "http_ingress_cidr" {
  description = "CIDR yang diizinkan mengakses port HTTP (80)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# --- EC2 ---
variable "ami_id" {
  description = "AMI ID untuk EC2 instance"
  type        = string
  default     = "ami-df5de72d"
}

variable "instance_type" {
  description = "Tipe EC2 instance"
  type        = string
  default     = "t2.micro"
}
