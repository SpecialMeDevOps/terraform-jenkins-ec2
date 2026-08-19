variable "aws_region" {
  description = "AWS region in which to deploy Jenkins."
  type        = string
  default     = "us-east-1"
}

variable "key_pair_mode" {
  description = "Whether to create a new EC2 key pair or use an existing one."
  type        = string
  default     = "existing"

  validation {
    condition     = contains(["create", "existing"], var.key_pair_mode)
    error_message = "key_pair_mode must be either create or existing."
  }
}

variable "existing_key_name" {
  description = "Name of an existing EC2 key pair when key_pair_mode is existing."
  type        = string
  default     = null
}

variable "new_key_pair_name" {
  description = "Name for the generated EC2 key pair when key_pair_mode is create."
  type        = string
  default     = "jenkins-key"
}

variable "vpc_mode" {
  description = "Whether to use the default VPC, create a new VPC, or use an existing VPC."
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "create", "existing"], var.vpc_mode)
    error_message = "vpc_mode must be default, create, or existing."
  }
}

variable "existing_vpc_id" {
  description = "ID of an existing VPC when vpc_mode is existing."
  type        = string
  default     = null
}

variable "existing_subnet_id" {
  description = "ID of an existing public subnet in existing_vpc_id when vpc_mode is existing."
  type        = string
  default     = null
}

variable "security_group_mode" {
  description = "Whether to create a Jenkins security group or use an existing one."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.security_group_mode)
    error_message = "security_group_mode must be either create or existing."
  }
}

variable "existing_security_group_id" {
  description = "ID of an existing security group when security_group_mode is existing."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins."
  type        = string
  default     = "t2.medium"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to Jenkins."
  type        = string
  default     = "0.0.0.0/0"
}

variable "jenkins_version" {
  description = "Jenkins package version. Leave empty to install the latest stable release."
  type        = string
  default     = ""
}