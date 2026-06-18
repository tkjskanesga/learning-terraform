# Provider LocalStack
variable "aws_region" {
  description = "aws region yang digunakan"
  type        = string
  default     = "us-east-1"
}

variable "localstack_endpoint" {
  description = "url endpoint localstack untuk ec2"
  type        = string
  default     = "http://localhost:4566"
}

# project
variable "project_name" {
  description = "nama project, digunakan sebagai suffix pada tag name"
  type        = string
  default     = "localstack"
}

# vpc & network
variable "vpc_cidr" {
  description = "cidr blok untuk vpc"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "cidr blok untuk public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "cidr blok untuk private subent"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "availability zone yang digunakan subnet"
  type        = string
  default     = "us-east-1"
}

# security group
variable "ssh_ingress_cidr" {
  description = "cidr yang diizinkan untuk mengakses port ssh"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "http_ingress_cidr" {
  description = "cidr yang diizinkan untuk mengakses port http"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ec2
variable "ami_id" {
  description = "ami id untuk ec2 instance"
  type        = string
  default     = "ami-b6389f37"
}

variable "instance_type" {
  description = "tipe ec2 instance"
  type        = string
  default     = "t2.micro"
}