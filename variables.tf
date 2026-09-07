variable "aws_region" {
  description = "AWS region in which to deploy."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix applied to resource names."
  type        = string
  default     = "jenkins-lab"
}

variable "key_pair_mode" {
  description = "Use an existing EC2 key pair or create one (private key is stored in state)."
  type        = string
  default     = "create"
  validation {
    condition     = contains(["create", "existing"], var.key_pair_mode)
    error_message = "key_pair_mode must be create or existing."
  }
}

variable "existing_key_name" {
  description = "Existing EC2 key pair name."
  type        = string
  default     = null
  validation {
    condition     = var.key_pair_mode == "create" || var.existing_key_name != null
    error_message = "existing_key_name is required when key_pair_mode is existing."
  }
}

variable "new_key_pair_name" {
  description = "Name of the generated EC2 key pair."
  type        = string
  default     = "jenkins-lab-key"
}

variable "vpc_mode" {
  description = "Use the default VPC, create a VPC, or use an existing VPC."
  type        = string
  default     = "default"
  validation {
    condition     = contains(["default", "create", "existing"], var.vpc_mode)
    error_message = "vpc_mode must be default, create, or existing."
  }
}

variable "existing_vpc_id" {
  description = "Existing VPC ID when vpc_mode is existing."
  type        = string
  default     = null
  validation {
    condition     = var.vpc_mode != "existing" || var.existing_vpc_id != null
    error_message = "existing_vpc_id is required when vpc_mode is existing."
  }
}

variable "existing_subnet_id" {
  description = "Existing public subnet ID when vpc_mode is existing."
  type        = string
  default     = null
  validation {
    condition     = var.vpc_mode != "existing" || var.existing_subnet_id != null
    error_message = "existing_subnet_id is required when vpc_mode is existing."
  }
}

variable "security_group_mode" {
  description = "Create a security group or use an existing one."
  type        = string
  default     = "create"
  validation {
    condition     = contains(["create", "existing"], var.security_group_mode)
    error_message = "security_group_mode must be create or existing."
  }
}

variable "existing_security_group_id" {
  description = "Existing security group ID when security_group_mode is existing."
  type        = string
  default     = null
  validation {
    condition     = var.security_group_mode != "existing" || var.existing_security_group_id != null
    error_message = "existing_security_group_id is required when security_group_mode is existing."
  }
}

variable "controller_instance_type" {
  description = "EC2 type for the Jenkins controller."
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "EC2 type for the worker/lab node."
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Encrypted root volume size in GiB."
  type        = number
  default     = 30
}

variable "associate_public_ip_address" {
  description = "Assign public IPs. Set false when using private subnets/NAT or SSM."
  type        = bool
  default     = true
}

variable "allowed_ssh_cidr" {
  description = "Single CIDR allowed to SSH (use your public IP/32)."
  type        = string
  default     = "10.0.0.0/8"
}

variable "allowed_jenkins_cidr" {
  description = "Single CIDR allowed to reach Jenkins on TCP/8080."
  type        = string
  default     = "10.0.0.0/8"
}

variable "enable_public_web_ingress" {
  description = "Open TCP 80/443 publicly; keep false unless a reverse proxy is configured."
  type        = bool
  default     = false
}

variable "create_iam_instance_profile" {
  description = "Create a least-privilege role/profile with SSM access for both instances."
  type        = bool
  default     = true
}

variable "iam_instance_profile_name" {
  description = "Existing instance profile name when creation is disabled."
  type        = string
  default     = null
  validation {
    condition     = var.create_iam_instance_profile || var.iam_instance_profile_name != null
    error_message = "iam_instance_profile_name is required when profile creation is disabled."
  }
}

variable "tags" {
  description = "Additional tags applied to managed resources."
  type        = map(string)
  default     = {}
}
