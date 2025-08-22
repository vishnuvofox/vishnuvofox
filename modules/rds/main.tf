resource "aws_db_instance" "this" {
  identifier             = var.identifier
  engine                 = "postgres"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  db_name                = var.rds_db_name
  username               = var.username
  password               = var.db_password
  multi_az               = var.multi_az
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.rds_sg_id]
  storage_encrypted      = true
  skip_final_snapshot    = true # Change to false in production
  publicly_accessible    = false
  deletion_protection    = false # Change to true in production

  tags = {
    Name = var.identifier
  }
}


