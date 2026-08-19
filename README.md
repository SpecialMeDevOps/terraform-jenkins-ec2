# Jenkins on EC2 with Terraform

This configuration deploys one EC2 instance running Jenkins. The resource choices are controlled through variables: create or reuse a key pair, create or reuse a security group, and use the default VPC, create a new VPC, or use an existing VPC.

The instance has exactly one security group. It allows SSH on TCP `22` from `allowed_ssh_cidr`, Jenkins on TCP `8080` from the internet, Jenkins inbound agents on TCP `50000` from the internet, and all outbound traffic.

## Deploy

1. Make sure AWS credentials are available.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and select the desired resource modes.
3. Run `terraform init`, `terraform plan`, and `terraform apply`.

For `key_pair_mode = "create"`, Terraform generates the key pair and exposes the private key as the sensitive `generated_private_key` output. Save it securely with `terraform output -raw generated_private_key > jenkins-key.pem` and restrict its permissions before SSH. For `key_pair_mode = "existing"`, set `existing_key_name` to the AWS key pair name.

For `vpc_mode = "existing"`, set both `existing_vpc_id` and `existing_subnet_id`; the subnet must have internet access and assign public IP addresses. For `security_group_mode = "existing"`, set `existing_security_group_id`; that security group must already allow SSH on `22`, Jenkins on `8080`, and agents on `50000`.

Terraform prints the Jenkins URL and an SSH command after the instance is created. The first boot installs Jenkins and can take a few minutes. Retrieve the initial administrator password after SSH access is available:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Destroy the environment with `terraform destroy` when it is no longer needed.