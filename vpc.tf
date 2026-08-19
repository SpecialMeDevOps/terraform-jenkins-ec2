data "aws_vpcs" "default" {
  count = var.vpc_mode == "default" ? 1 : 0

  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnets" "default" {
  count = var.vpc_mode == "default" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpcs.default[0].ids[0]]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  create_vpc = var.vpc_mode == "create"
  vpc_id     = var.vpc_mode == "default" ? data.aws_vpcs.default[0].ids[0] : var.vpc_mode == "existing" ? var.existing_vpc_id : aws_vpc.jenkins[0].id
  subnet_id  = var.vpc_mode == "default" ? data.aws_subnets.default[0].ids[0] : var.vpc_mode == "existing" ? var.existing_subnet_id : aws_subnet.jenkins[0].id
}

resource "aws_vpc" "jenkins" {
  count                = local.create_vpc ? 1 : 0
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "jenkins-vpc"
  }
}

resource "aws_subnet" "jenkins" {
  count                   = local.create_vpc ? 1 : 0
  vpc_id                  = aws_vpc.jenkins[0].id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "jenkins-public-subnet"
  }
}

resource "aws_internet_gateway" "jenkins" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.jenkins[0].id
}

resource "aws_route_table" "jenkins" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.jenkins[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins[0].id
  }
}

resource "aws_route_table_association" "jenkins" {
  count          = local.create_vpc ? 1 : 0
  subnet_id      = aws_subnet.jenkins[0].id
  route_table_id = aws_route_table.jenkins[0].id
}