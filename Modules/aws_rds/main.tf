resource "aws_db_subnet_group" "rds" {
  name_prefix = "rds-subnet-group"
  description = "Database subnet group for RDS"
  subnet_ids  = var.subnet_ids

  tags = {
    Name = "rds_subnet_group"
  }
}

resource "aws_db_parameter_group" "rds" {
  name_prefix = "rds-parameter-group"
  description = "Database parameter group for RDS"
  family      = var.family

  tags = {
    Name = "rds_parameter_group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "this" {
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  identifier = var.identifier
  name     = var.name
  username = var.username
  password = var.password
  port     = var.port

  replicate_source_db = var.replicate_source_db

  snapshot_identifier = var.snapshot_identifier

  vpc_security_group_ids = [aws_security_group.main_rds_access.id]
  db_subnet_group_name   = aws_db_subnet_group.rds.id
  parameter_group_name   = aws_db_parameter_group.rds.id

  availability_zone   = var.availability_zone
  multi_az            = var.multi_az
  publicly_accessible = var.publicly_accessible

  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  apply_immediately           = var.apply_immediately
  skip_final_snapshot         = var.skip_final_snapshot
  copy_tags_to_snapshot       = var.copy_tags_to_snapshot
  final_snapshot_identifier   = var.final_snapshot_identifier

  tags = {
    Name = "rds_db"
  }
}

# Security groups
resource "aws_security_group" "main_rds_access" {
  name        = "RDS-access"
  description = "Allow access to RDS"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_port_inbound" {
  type = "ingress"

  from_port   = var.port
  to_port     = var.port
  protocol    = "tcp"
  cidr_blocks = var.private_cidr

  security_group_id = aws_security_group.main_rds_access.id
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.main_rds_access.id
}
