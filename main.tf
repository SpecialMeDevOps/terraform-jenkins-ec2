data "aws_vpcs" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnets" "default" {
  count = local.use_default_vpc ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpcs.default.ids[0]]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

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
  use_default_vpc = length(data.aws_vpcs.default.ids) > 0
  vpc_id          = local.use_default_vpc ? data.aws_vpcs.default.ids[0] : aws_vpc.jenkins[0].id
  subnet_id       = local.use_default_vpc ? data.aws_subnets.default[0].ids[0] : aws_subnet.jenkins[0].id
}

resource "aws_vpc" "jenkins" {
  count                = local.use_default_vpc ? 0 : 1
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "jenkins-vpc"
  }
}

resource "aws_subnet" "jenkins" {
  count                   = local.use_default_vpc ? 0 : 1
  vpc_id                  = aws_vpc.jenkins[0].id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "jenkins-public-subnet"
  }
}

resource "aws_internet_gateway" "jenkins" {
  count  = local.use_default_vpc ? 0 : 1
  vpc_id = aws_vpc.jenkins[0].id
}

resource "aws_route_table" "jenkins" {
  count  = local.use_default_vpc ? 0 : 1
  vpc_id = aws_vpc.jenkins[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins[0].id
  }
}

resource "aws_route_table_association" "jenkins" {
  count          = local.use_default_vpc ? 0 : 1
  subnet_id      = aws_subnet.jenkins[0].id
  route_table_id = aws_route_table.jenkins[0].id
}

resource "aws_security_group" "jenkins" {
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

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

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