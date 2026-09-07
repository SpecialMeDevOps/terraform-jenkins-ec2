locals {
  security_group_id = var.security_group_mode == "create" ? aws_security_group.jenkins[0].id : var.existing_security_group_id
}

resource "aws_security_group" "jenkins" {
  count       = var.security_group_mode == "create" ? 1 : 0
  name        = "${var.name_prefix}-instances"
  description = "Least-privilege access for the Jenkins lab instances"
  vpc_id      = local.vpc_id

  ingress {
    description = "SSH from the operator network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Jenkins UI from the explicitly approved network"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_jenkins_cidr]
  }

  dynamic "ingress" {
    for_each = var.enable_public_web_ingress ? [1] : []
    content {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = var.enable_public_web_ingress ? [1] : []
    content {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "Outbound updates and package downloads"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-instances" })
}
