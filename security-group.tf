locals {
  security_group_id = var.security_group_mode == "create" ? aws_security_group.jenkins[0].id : var.existing_security_group_id
}

resource "aws_security_group" "jenkins" {
  count       = var.security_group_mode == "create" ? 1 : 0
  name        = "jenkins-instance"
  description = "SSH, Jenkins web UI, and inbound Jenkins agent access"
  vpc_id      = local.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Jenkins web interface"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins inbound agent listener"
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-instance"
  }
}