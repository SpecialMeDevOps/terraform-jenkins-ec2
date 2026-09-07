# Jenkins controller and Ubuntu lab worker

Terraform provisions a small, repeatable DevOps lab in AWS: two Ubuntu Server
24.04 LTS EC2 instances, a configurable network/security group, and optional
least-privilege IAM instance profiles. The hosts are intentionally separate.
The controller and worker both install Jenkins and the same toolchain, but this
repository does **not** configure Jenkins controller/agent communication.

## Status and scope

**Status:** infrastructure and host bootstrap are implemented; CI validation is
implemented; application CI/CD pipelines and Jenkins agent enrollment are not.
This is a foundation for a lab, not a production Jenkins service. No credentials,
agent secrets, SSH trust material, or access keys are generated.

## Architecture

```mermaid
flowchart LR
  operator[Operator] -->|SSH 22, restricted CIDR| sg[EC2 security group]
  operator -->|HTTP 8080, restricted CIDR| sg
  sg --> controller[controller\nUbuntu 24.04\nJenkins + tools]
  sg --> worker[worker/lab node\nUbuntu 24.04\nJenkins + tools]
  controller -.->|No agent enrollment configured| worker
  controller --> role[IAM instance profile\nSSM core only]
  worker --> role
  role --> ssm[AWS Systems Manager]
```

The default VPC mode uses the first available subnet in the account default VPC.
`vpc_mode = "create"` creates a small public VPC/subnet/route table; production
deployments should use a reviewed network design and private subnets where
possible. Public IP assignment is configurable.

## Repository structure

```text
.
├── ec2.tf                         # controller and worker instances
├── iam.tf                         # EC2 role, profile, and SSM policy attachment
├── vpc.tf                         # default, created, or existing VPC selection
├── security-group.tf              # configurable SSH/Jenkins/web ingress
├── variables.tf                   # inputs and validations
├── outputs.tf                     # IDs, public/private IPs, SSH and Jenkins URL
├── versions.tf                    # Terraform and provider constraints
├── scripts/
│   ├── controller-user-data.sh    # controller bootstrap
│   └── worker-user-data.sh        # worker bootstrap
├── .github/workflows/
│   └── terraform.yml              # fmt/init/validate/TFLint/Checkov
├── .tflint.hcl                    # AWS TFLint ruleset
└── terraform.tfvars.example       # safe configuration example
```

## Technology

| Area | Implementation |
| --- | --- |
| IaC | Terraform >= 1.5, AWS provider ~> 5.0 |
| Operating system | Ubuntu Server 24.04 LTS amd64 AMI |
| Compute | Two configurable EC2 instances (default `t3.medium`) |
| Containers | Docker Engine from Docker's official apt repository and Compose plugin |
| Kubernetes tools | Stable `kubectl` release and Helm from the official repository |
| Cloud tooling | AWS CLI v2 official installer and Terraform HashiCorp apt repository |
| Automation | Jenkins and Java 21 on both hosts |
| Access | EC2 key pair, IMDSv2, optional SSM |
| Static CI | GitHub Actions, TFLint, Checkov |

## Prerequisites and authentication

Install Terraform >= 1.5 and have an AWS account with permission to create the
selected VPC/subnet, security group, EC2 instances, IAM role/profile, and key
pair. Use AWS CLI configuration, environment variables, or another standard
AWS provider credential chain. Never put credentials in `terraform.tfvars`,
user data, GitHub Actions, or this repository.

An existing EC2 key pair is recommended. If `key_pair_mode = "create"`, Terraform
creates an ED25519 key and exposes the private key as a sensitive output; because
that value is stored in state, protect state as carefully as a secret.

## Configuration and deployment

```bash
cp terraform.tfvars.example terraform.tfvars
# Set existing_key_name and narrow allowed_ssh_cidr/allowed_jenkins_cidr.
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Important inputs include:

* `aws_region`, `name_prefix`
* `vpc_mode`, `existing_vpc_id`, `existing_subnet_id`
* `controller_instance_type`, `worker_instance_type`, `root_volume_size`
* `key_pair_mode`, `existing_key_name`, `new_key_pair_name`
* `allowed_ssh_cidr` and `allowed_jenkins_cidr`
* `associate_public_ip_address` and `enable_public_web_ingress`
* `create_iam_instance_profile` or `iam_instance_profile_name`

The default security group allows SSH and Jenkins only from the two configured
CIDRs. HTTP/HTTPS ingress is disabled. Do not use `0.0.0.0/0` for administration
or Jenkins except briefly in an isolated test.

## Outputs, IPs, and SSH

After apply, inspect all values with:

```bash
terraform output
terraform output ssh_commands
terraform output controller_private_ip
terraform output worker_private_ip
```

Outputs include controller/worker instance IDs, public IPs (when public
addressing is enabled), private IPs, SSH command examples, the controller
Jenkins URL, and a sensitive generated private key when requested. Example SSH:

```bash
ssh -i <private-key> ubuntu@<controller-public-ip>
ssh -i <private-key> ubuntu@<worker-public-ip>
```

For private instances, use SSM Session Manager or a bastion/VPN path instead of
opening SSH publicly. The SSM role is attached automatically when the module
creates its profile.

## Host bootstrap and tool verification

Terraform passes `scripts/controller-user-data.sh` and
`scripts/worker-user-data.sh` as EC2 user data. Both scripts are idempotent for
package/repository installation, log to
`/var/log/jenkins-controller-bootstrap.log` or
`/var/log/jenkins-worker-bootstrap.log`, fail fast, and print a verification
summary. They use `/var/lib/jenkins-lab/downloads` for downloads and do not
write credentials.

On either host, start a new SSH session after Docker group membership changes:

```bash
git --version
docker --version
docker compose version
kubectl version --client
helm version
aws --version
terraform version
systemctl is-active jenkins
```

Retrieve the initial Jenkins password only on the relevant host:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## Jenkins controller versus worker

The `controller` is the recommended Jenkins UI host and is the target of the
`controller_jenkins_url` output. The `worker` is a second practice environment
with Jenkins installed for symmetry and independent experimentation. It is not
automatically a Jenkins build agent: there is no agent port rule, controller
URL, node definition, secret, or SSH key exchange. If agent enrollment is later
desired, implement it explicitly with a least-privilege, documented design.

## CI flow and CI/CD distinction

`.github/workflows/terraform.yml` runs on pull requests and pushes to `main`:

1. Checkout.
2. Install Terraform and TFLint.
3. Run `terraform fmt -check -recursive`.
4. Run offline `terraform init`.
5. Run `terraform validate`.
6. Initialize and run TFLint.
7. Run Checkov against Terraform.

The workflow has read-only contents permission and performs no plan or apply.
This is **CI** (formatting, static analysis, and validation), not deployment
**CD**. Jenkins pipelines, artifact promotion, approvals, drift detection, and
automatic infrastructure deployment are intentionally outside this repository.

## Security and state

IMDSv2 is required, root disks are encrypted gp3 volumes, and IAM uses the
AWS-managed `AmazonSSMManagedInstanceCore` policy only by default. Review that
policy and add no broader permissions unless required by a workload. Restrict
CIDRs, protect Terraform state with encryption/access controls and locking, and
do not commit `terraform.tfvars`, state files, generated keys, or logs.

## Troubleshooting

* **No Jenkins page:** verify the controller public/private route, the
  `allowed_jenkins_cidr`, `systemctl status jenkins`, and the bootstrap log.
* **SSH denied:** check the key pair, effective public IP, subnet route, and
  `allowed_ssh_cidr`; avoid changing the group to world-open.
* **Tool missing:** inspect the relevant bootstrap log and rerun only after
  correcting the underlying apt/network issue; user data runs at first boot.
* **Docker permission denied:** reconnect so the `ubuntu` group membership is
  refreshed, or use `sudo` temporarily.
* **SSM unavailable:** confirm the profile is attached, the instance has
  outbound access or VPC endpoints, and the SSM agent is running.

## Cleanup

Review the plan and remove all lab resources when finished:

```bash
terraform plan -destroy
terraform destroy
```

If an existing VPC, subnet, security group, key pair, or IAM profile was
supplied, Terraform does not own or destroy those external resources.

## Roadmap

Possible follow-up work includes private-subnet/NAT or VPC-endpoint examples,
remote encrypted state with locking, HTTPS via a reverse proxy/load balancer,
CloudWatch/bootstrap health reporting, Jenkins configuration-as-code, and a
separately reviewed secure agent enrollment workflow.

## Interview and resume summary

This project demonstrates Terraform module design, AWS EC2/VPC/IAM security,
IMDSv2 and encrypted storage, reproducible Ubuntu bootstrapping, Docker and
Kubernetes tooling installation, and policy-as-code CI. A concise resume entry:

> Built a Terraform-managed Ubuntu 24.04 Jenkins lab with separate controller
> and worker EC2 nodes, least-privilege SSM IAM profiles, restricted security
> groups, reproducible tool bootstrap, and GitHub Actions validation using
> TFLint and Checkov.
