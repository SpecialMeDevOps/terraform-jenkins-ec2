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

data "aws_ec2_instance_type_offerings" "controller" {
  location_type = "availability-zone"

  filter {
    name   = "instance-type"
    values = [var.controller_instance_type]
  }
}

data "aws_ec2_instance_type_offerings" "worker" {
  location_type = "availability-zone"

  filter {
    name   = "instance-type"
    values = [var.worker_instance_type]
  }
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

data "aws_subnet" "default" {
  for_each = var.vpc_mode == "default" ? toset(data.aws_subnets.default[0].ids) : toset([])
  id       = each.value
}

data "aws_subnet" "existing" {
  count = var.vpc_mode == "existing" ? 1 : 0
  id    = var.existing_subnet_id
}

data "aws_route_table" "selected" {
  for_each       = var.vpc_mode == "create" ? toset([]) : toset(data.aws_route_tables.vpc[0].ids)
  route_table_id = each.value
}

data "aws_route_tables" "vpc" {
  count = var.vpc_mode == "create" ? 0 : 1

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

locals {
  create_vpc = var.vpc_mode == "create"
  supported_azs = sort(setintersection(
    toset(data.aws_availability_zones.available.names),
    toset(data.aws_ec2_instance_type_offerings.controller.locations),
    toset(data.aws_ec2_instance_type_offerings.worker.locations),
  ))
  default_compatible_subnets = sort([
    for id, subnet in data.aws_subnet.default :
    id if contains(local.supported_azs, subnet.availability_zone)
  ])
  selected_az = var.vpc_mode == "create" ? local.supported_azs[0] : var.vpc_mode == "default" ? data.aws_subnet.default[local.default_compatible_subnets[0]].availability_zone : data.aws_subnet.existing[0].availability_zone
  vpc_id      = var.vpc_mode == "default" ? data.aws_vpcs.default[0].ids[0] : var.vpc_mode == "existing" ? var.existing_vpc_id : aws_vpc.jenkins[0].id
  subnet_id   = var.vpc_mode == "default" ? local.default_compatible_subnets[0] : var.vpc_mode == "existing" ? var.existing_subnet_id : aws_subnet.jenkins[0].id
  has_internet_route = var.vpc_mode == "create" || anytrue(flatten([
    for table in data.aws_route_table.selected : [
      for route in table.routes : route.cidr_block == "0.0.0.0/0" && (
        route.gateway_id != null || route.nat_gateway_id != null || route.egress_only_gateway_id != null
        ) && anytrue([
          for association in table.associations : association.main || association.subnet_id == local.subnet_id
      ])
    ]
  ]))
}

check "compatible_instance_availability" {
  assert {
    condition     = length(local.supported_azs) > 0
    error_message = "No Availability Zone supports both instance types in ${var.aws_region}."
  }
}

check "compatible_default_subnet" {
  assert {
    condition     = var.vpc_mode != "default" || length(local.default_compatible_subnets) > 0
    error_message = "The default VPC has no subnet in an Availability Zone supporting both instance types."
  }
}

check "compatible_existing_subnet" {
  assert {
    condition     = var.vpc_mode != "existing" || contains(local.supported_azs, data.aws_subnet.existing[0].availability_zone)
    error_message = "The existing subnet's Availability Zone does not support both configured instance types."
  }
}

check "public_network_reachability" {
  assert {
    condition     = !var.associate_public_ip_address || local.has_internet_route
    error_message = "The selected subnet has no usable default route. Disable public IPs for private networking or select/configure a subnet with an internet/NAT route."
  }
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
  availability_zone       = local.selected_az
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