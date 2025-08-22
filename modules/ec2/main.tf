resource "aws_key_pair" "hapi" {
  key_name   = "${var.environment}-kp-hapi"
  public_key = file("${path.module}/vofox.pub")
  tags = {
    Name        = "${var.environment}-kp-hapi"
    Environment = var.environment
    Project     = "FHIR"
  }
}

resource "aws_instance" "main" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.iam_instance_profile
  key_name               = aws_key_pair.hapi.key_name
  user_data = <<-EOF
              #!/bin/bash
              echo "Waiting for /tmp/script.sql..."

              while [ ! -f /tmp/script.sql ]; do
                echo "Waiting for script.sql to appear..."
                sleep 5
              done

              echo "Verifying SHA256 checksum..."
              FILE_HASH=$(sha256sum /tmp/script.sql | awk '{ print toupper($1) }')
              EXPECTED_HASH="6A991BD687DFCEBABFF6CDC3B61C43449EF8E937D12A4E57210081E8D1643D15"

              if [ "$FILE_HASH" != "$EXPECTED_HASH" ]; then
                echo "SHA256 mismatch. Got: $FILE_HASH"
                exit 1
              fi

              echo "Installing PostgreSQL client..."
              sudo apt update -y
              sudo apt install -y postgresql-client

              echo "Running SQL script on RDS..."
              export PGPASSWORD="${var.rds_password}"
              pg_restore -h ${var.rds_endpoint} -U ${var.rds_username} -d ${var.rds_db_name} --verbose /tmp/script.sql > /tmp/pg_restore.log 2>&1

              if [ $? -eq 0 ]; then
                echo "Database restore completed successfully."
              else
                echo "Error during database restore. Check /tmp/pg_restore.log for details."
                exit 1
              fi

              echo "Cleaning up..."
              rm -f /tmp/script.sql

              echo "Done."
              EOF

  tags = {
    Name        = "${var.environment}-ec2-hapi-instance"
    Environment = var.environment
    Project     = "FHIR"
  }
}

resource "null_resource" "upload_script" {
  depends_on = [aws_instance.main]

  provisioner "local-exec" {
    command = <<EOT
      powershell -Command "scp -i '${path.module}/vofox' -o StrictHostKeyChecking=no '${path.module}/script.sql' ubuntu@${aws_instance.main.public_ip}:/tmp/script.sql"
    EOT
  }
}
