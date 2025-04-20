# RDS PostgreSQL instance
resource "aws_db_instance" "postgres" {
  identifier             = var.db_identifier
  engine                 = "postgres"
  engine_version         = "15.8"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp2"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.postgres15"
  skip_final_snapshot    = true
  deletion_protection    = var.environment == "production"
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = var.publicly_accessible
  backup_retention_period = var.environment == "production" ? 7 : 1
  multi_az               = var.environment == "production"

  tags = {
    Name        = "${var.project_name}-database"
    Environment = var.environment
    Project     = var.project_name
  }
}