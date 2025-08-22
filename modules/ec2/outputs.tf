output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "public_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.main.public_ip
}