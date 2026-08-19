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