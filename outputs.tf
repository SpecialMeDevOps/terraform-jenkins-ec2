output "instance_id" {
  description = "ID of the Jenkins EC2 instance."
  value       = aws_instance.jenkins.id
}

output "public_ip" {
  description = "Public IP address used to connect to Jenkins and SSH."
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins web interface URL."
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "ssh_command" {
  description = "Example SSH command for the Amazon Linux host."
  value       = "ssh -i <path-to-private-key> ec2-user@${aws_instance.jenkins.public_ip}"
}

output "generated_private_key" {
  description = "Private key for the generated EC2 key pair. Save it securely when key_pair_mode is create."
  value       = var.key_pair_mode == "create" ? tls_private_key.jenkins[0].private_key_openssh : null
  sensitive   = true
}