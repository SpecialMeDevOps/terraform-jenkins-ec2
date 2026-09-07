data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  create_key_pair  = var.key_pair_mode == "create"
  key_name         = local.create_key_pair ? aws_key_pair.jenkins[0].key_name : var.existing_key_name
  instance_profile = var.create_iam_instance_profile ? aws_iam_instance_profile.jenkins[0].name : var.iam_instance_profile_name
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

resource "aws_instance" "controller" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.controller_instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [local.security_group_id]
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = local.key_name
  iam_instance_profile        = local.instance_profile
  monitoring                  = true
  ebs_optimized               = true
  user_data                   = file("${path.module}/scripts/controller-user-data.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-controller"
    Role = "controller"
  })
}

resource "aws_instance" "worker" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.worker_instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [local.security_group_id]
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = local.key_name
  iam_instance_profile        = local.instance_profile
  monitoring                  = true
  ebs_optimized               = true
  user_data                   = file("${path.module}/scripts/worker-user-data.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-worker"
    Role = "worker"
  })
}
