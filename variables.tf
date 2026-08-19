variable "aws_region" {
  description = "AWS region in which to deploy Jenkins."
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair used for SSH access."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins."
  type        = string
  default     = "t3.small"
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