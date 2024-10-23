provider "aws" {
  region = "us-west-2" # Change to your desired region
}

# Create EFS
resource "aws_efs_file_system" "example" {
  creation_token = "enable-automatic-snapshots"
  performance_mode = "generalPurpose"
  lifecycle {
    create_before_destroy = true
  }

  provisioned_throughput_in_mibps = 0 # Default value for general purpose mode
}

resource "aws_efs_mount_target" "example" {
  for_each          = toset(data.aws_availability_zones.available.names)
  file_system_id   = aws_efs_file_system.example.id
  subnet_id        = aws_subnet.example.id # Replace with your subnet ID

  lifecycle {
    create_before_destroy = true
  }
}

# Enable automatic snapshots with lifecycle management
resource "aws_efs_lifecycle_policy" "example" {
  file_system_id = aws_efs_file_system.example.id
  transition_to_ia = "AFTER_30_DAYS" # Move files to Infrequent Access after 30 days
}

# Create a security group for the EC2 instance
resource "aws_security_group" "example" {
  name        = "efs-security-group"
  description = "Allow NFS traffic"
  vpc_id      = aws_vpc.example.id # Replace with your VPC ID

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with appropriate CIDR blocks for security
  }
}

# Create EC2 instance
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe01e" # Replace with your desired AMI
  instance_type = "t2.micro" # Choose your instance type
  subnet_id     = aws_subnet.example.id # Replace with your subnet ID
  security_groups = [aws_security_group.example.name]

  user_data = <<-EOF
              #!/bin/bash
              yum install -y amazon-efs-utils
              mkdir /mnt/efs
              mount -t efs ${aws_efs_file_system.example.id}:/ /mnt/efs
              EOF
}

# Create a VPC (optional, if you don't have one)
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

# Create a subnet
resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, 0)
}

data "aws_availability_zones" "available" {}

output "efs_file_system_id" {
  value = aws_efs_file_system.example.id
}

output "ec2_instance_id" {
  value = aws_instance.example.id
}
