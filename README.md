# Jenkins on EC2 with Terraform

This configuration deploys one EC2 instance running Jenkins. It uses the region's default VPC when one exists. If no default VPC exists, Terraform creates one public subnet, an internet gateway, a route table, and the required association.

The instance has exactly one security group. It allows SSH on TCP `22` from `allowed_ssh_cidr`, Jenkins on TCP `8080` from the internet, Jenkins inbound agents on TCP `50000` from the internet, and all outbound traffic.

## Deploy

1. Make sure AWS credentials are available and create an EC2 key pair in the target region.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and set `key_name` and `allowed_ssh_cidr`.
3. Run `terraform init`, `terraform plan`, and `terraform apply`.

Terraform prints the Jenkins URL and an SSH command after the instance is created. The first boot installs Jenkins and can take a few minutes. Retrieve the initial administrator password after SSH access is available:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Destroy the environment with `terraform destroy` when it is no longer needed.