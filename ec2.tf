data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  create_key_pair = var.key_pair_mode == "create"
  key_name        = local.create_key_pair ? aws_key_pair.jenkins[0].key_name : var.existing_key_name
}

resource "tls_private_key" "jenkins" {
  count     = local.create_key_pair ? 1 : 0
  algorithm = "ED25519"
}

resource "aws_key_pair" "jenkins" {
  count      = local.create_key_pair ? 1 : 0
  key_name   = var.new_key_pair_name
  public_key = tls_private_key.jenkins[0].public_key_openssh
}

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [local.security_group_id]
  associate_public_ip_address = true
  key_name                    = local.key_name

  user_data = templatefile("${path.module}/jenkins-user-data.sh.tftpl", {
    jenkins_version = var.jenkins_version
  })

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "jenkins"
  }
}