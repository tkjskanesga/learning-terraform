terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ==========================================
# 1. PROVIDER CONFIGURATION (LOCALSTACK)
# ==========================================
provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
  }
}

# ==========================================
# 2. VPC & INTERNET GATEWAY
# ==========================================
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-localstack"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "igw-localstack"
  }
}

# ==========================================
# 3. SUBNETS (PUBLIC & PRIVATE)
# ==========================================
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "public-subnet-localstack"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"

  tags = {
    Name = "private-subnet-localstack"
  }
}

# ==========================================
# 4. NAT GATEWAY (Untuk Private Subnet)
# ==========================================
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "my_nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id # NAT GW selalu ditaruh di Public Subnet

  tags = {
    Name = "nat-gateway-localstack"
  }

  depends_on = [aws_internet_gateway.my_igw]
}

# ==========================================
# 5. ROUTE TABLES & ASSOCIATIONS
# ==========================================
# Public Route Table (Arah ke Internet Gateway)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table (Arah ke NAT Gateway)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat_gw.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# ==========================================
# 6. SECURITY GROUP
# ==========================================
resource "aws_security_group" "web_sg" {
  name        = "allow_web_traffic"
  description = "Allow inbound SSH and HTTP"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "web-security-group"
  }
}

# ==========================================
# 7. EC2 INSTANCES
# ==========================================
# Server Web di Public Subnet
resource "aws_instance" "web_server" {
  ami                    = "ami-df5de72d" 
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "Web-Server-Public"
  }
}

# Server Database di Private Subnet
resource "aws_instance" "db_server" {
  ami                    = "ami-df5de72d" 
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet.id
  # Secara ideal DB punya Security Group sendiri, 
  # tapi untuk simulasi kita pakai yang sama dulu
  vpc_security_group_ids = [aws_security_group.web_sg.id] 

  tags = {
    Name = "DB-Server-Private"
  }
}