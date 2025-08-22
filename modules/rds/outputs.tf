output "rds_endpoint" {
  value = aws_db_instance.this.address
}

output "rds_port" {
  value = aws_db_instance.this.port
}

output "rds_db_name" {
  value = aws_db_instance.this.db_name 
}

output "rds_password" {
  value     = aws_db_instance.this.password
  sensitive = true
}

output "rds_username" {
  value = aws_db_instance.this.username
}