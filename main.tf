terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 4.0"
      }
    }
}


provider "aws" {
    profile = "default"
    region  = "us-east-1"
}


data "aws_ami" "ubuntu" {
    most_recent = true
  
    filter {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
  
    filter {
      name   = "virtualization-type"
      values = ["hvm"]
    }
  
}

// SSH-KEY
resource "aws_key_pair" "deployer" {
   key_name   = "deployer-key"
   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC8OyPewfJ6G0f7fBLcdkC5xmOA23QLOD68/AYRfNt5hxBYVZqtOmJvuwVOOWfrpMueMwfTR35gbfhKheH1i1Q7+aIkDkxShc3ZF0wQnK/cemPtIbCQM2pLgBsgPtnobp15IK9dFmMUyoZvG/96rdpCU1iSRw2XTv63wLAfNCVZWCQEMWRb3Aa/rcrTt1OP8QaZuxP2qxpd1ZcDr6IavnEFOCmi7LIm6cybUI7ENyMDBhQGwwyfhnDO8MCDA0o/cwuQVdnnQuEvvoDoyHX2BmTzFaKFz60B7qHMACTZYefNMRv+CNGITMNgpoAlRTaJ1fKQh/78nS87LwB+s8yhWPtTjI04ADc4UZtlHplCxTYtsuUmPaOtKm6QwONJ73PgQztKc3Dbrvlr2c0FgsA7UI6cO0YUiYiXzwWf/AlBrms+qCAFg7mDXXOepDpEDLusF+ttLGQ/VmmrhJnsVE2AyTxjYrvkv+RJb8vTdOsLiwZRUPJn5OkJdGjG4uwRciXirfs= root@master"
} 

resource "aws_security_group" "my_security" {
    ingress {
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  
    ingress {
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  
    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  
    tags = {
      Name = "allow_tls"
    } 
}
  
resource "aws_instance" "web" {
    ami           = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    key_name      = aws_key_pair.deployer.key_name
    vpc_security_group_ids = [aws_security_group.my_security.id]

   user_data = <<-EOD
    #! /bin/bash
    sudo apt-get update
    sudo apt-get install -y apache2
    sudo systemctl start apache2
    sudo systemctl enable apache2
    echo "The page was created by the user data" | sudo tee /var/www/html/index.html
   EOD

   tags = {
      Name = "Test-Instance"
    }
}
