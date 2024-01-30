# Define variables
variable "aws_access_key" {
    default ="AKIA4TWKQEDUG6W7FEPM"
}
variable "aws_secret_key" {
    default = "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"
}
variable "region" {
  default = "eu-west-2"
}
variable "ami" {
  default = "ami-oaoedaad9092f8016" # Amazon Linux 2 AMI
}
variable "instance_type" {
  default = "t2.micro"
}
variable "subnet_cidr_public" {
  default = "10.0.1.0/24"
}
variable "subnet_cidr_public2" {
    default = "10.0.3.0/24"
}
variable "subnet_cidr_private" {
  default = "10.0.2.0/24"
}
variable "subnet_cidr_private2" {
    default = "10.0.4.0/24"
}

# Configure the AWS provider
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "my_vpc"
  }
}

# Create public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.subnet_cidr_public
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  }
}


# Create private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.subnet_cidr_private
  availability_zone       = "${var.region}b"
  tags = {
    Name = "private_subnet"
  }
}



# Create internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my_igw"
  }
}

# Create route table for public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create security group for EC2 instance
resource "aws_security_group" "my_sg" {
  name        = "my_sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Add other necessary rules based on your requirements
}

# Create EC2 instance
resource "aws_instance" "my_ec2_instance" {
  ami           = "ami-0a0edaad9092f8016"
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = "sindhukey" # Change this to your key pair name

  # Add other necessary configurations for your EC2 instance
}

# Create load balancer
resource "aws_lb" "my_lb" {
  name               = "mylb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_sg.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]

  enable_deletion_protection = false

  enable_cross_zone_load_balancing   = true
  enable_http2                       = true
  idle_timeout                       = 60
}

# Create listener rule for load balancer


# Create target group
resource "aws_lb_target_group" "my_targets_group" {
  name     = "mytargetgroups1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

# Register EC2 instance with the target group
resource "aws_lb_target_group_attachment" "my_target_group_attachment" {
  target_group_arn = aws_lb_target_group.my_targets_group.arn
  target_id        = aws_instance.my_ec2_instance.id
}