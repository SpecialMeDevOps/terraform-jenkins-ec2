output "controller_instance_id" {
  description = "Controller EC2 instance ID."
  value       = aws_instance.controller.id
}

output "controller_public_ip" {
  description = "Controller public IP, if public addressing is enabled."
  value       = aws_instance.controller.public_ip
}

output "controller_private_ip" {
  description = "Controller private IP address."
  value       = aws_instance.controller.private_ip
}

output "worker_instance_id" {
  description = "Worker/lab EC2 instance ID."
  value       = aws_instance.worker.id
}

output "worker_public_ip" {
  description = "Worker public IP, if public addressing is enabled."
  value       = aws_instance.worker.public_ip
}

output "worker_private_ip" {
  description = "Worker private IP address."
  value       = aws_instance.worker.private_ip
}

output "controller_jenkins_url" {
  description = "Jenkins UI URL; access is controlled by allowed_jenkins_cidr."
  value       = "http://${aws_instance.controller.public_ip}:8080"
}

output "ssh_commands" {
  description = "SSH commands for both hosts."
  value = {
    controller = "ssh -i <private-key> ubuntu@${aws_instance.controller.public_ip}"
    worker     = "ssh -i <private-key> ubuntu@${aws_instance.worker.public_ip}"
  }
}

output "generated_private_key" {
  description = "Sensitive private key generated for the EC2 key pair, when enabled."
  value       = var.key_pair_mode == "create" ? tls_private_key.jenkins[0].private_key_openssh : null
  sensitive   = true
}
