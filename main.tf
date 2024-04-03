terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.12"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "docker" {
  host = "tcp://localhost:2375"
}

resource "aws_vpc" "dock_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "dock_vpc"
  }
}

resource "aws_subnet" "dock_subnet" {
  vpc_id            = aws_vpc.dock_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "dock_subnet"
  }
}

resource "aws_internet_gateway" "dock_ITGW" {
  vpc_id = aws_vpc.dock_vpc.id

  tags = {
    Name = "dock_ITGW"
  }
}

resource "aws_route_table" "dock_route_table" {
  vpc_id = aws_vpc.dock_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dock_ITGW.id
  }

  tags = {
    Name = "dock_route_table"
  }
}

resource "aws_route_table_association" "associate_dock_route_table" {
  subnet_id      = aws_subnet.dock_subnet.id
  route_table_id = aws_route_table.dock_route_table.id
}

resource "aws_security_group" "dock_sg" {
  name        = "dock_sg"
  description = "Allow traffic for Docker"
  vpc_id      = aws_vpc.dock_vpc.id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port     = 22
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
    Name = "dock_sg"
  }
}

resource "aws_instance" "dock_server_Dev" {
  ami                    = "ami-080e1f13689e07408"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.dock_subnet.id
  vpc_security_group_ids = [aws_security_group.dock_sg.id]

  tags = {
    Name = "dock_server_Dev"
  }
}

resource "docker_container" "my_container" {
  name  = "my-container"
  image = "nginx:latest"
  ports {
    internal = 80
    external = 8080
  }
}
