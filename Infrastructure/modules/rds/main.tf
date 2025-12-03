# KMS Key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-rds-key"
    }
  )
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.identifier}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.identifier}-pg"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "max_connections"
    value = "200"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-parameter-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# DB Option Group
resource "aws_db_option_group" "main" {
  name                     = "${var.identifier}-og"
  option_group_description = "Option group for ${var.identifier}"
  engine_name              = "mysql"
  major_engine_version     = "8.0"

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-option-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier     = var.identifier
  engine         = "mysql"
  engine_version = "8.0.35"

  instance_class        = var.db_config.instance_class
  allocated_storage     = var.db_config.allocated_storage
  max_allocated_storage = var.db_config.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 3306

  multi_az               = var.db_config.multi_az
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false

  parameter_group_name = aws_db_parameter_group.main.name
  option_group_name    = aws_db_option_group.main.name

  backup_retention_period   = var.db_config.backup_retention_period
  backup_window             = "03:00-04:00"
  maintenance_window        = "mon:04:00-mon:05:00"
  auto_minor_version_upgrade = true
  
  deletion_protection       = var.db_config.deletion_protection
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null
  copy_tags_to_snapshot     = true

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
  performance_insights_retention_period = 7

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  tags = merge(
    var.tags,
    {
      Name = var.identifier
    }
  )

  lifecycle {
    ignore_changes = [
      password,
      final_snapshot_identifier
    ]
  }
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.identifier}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "${var.identifier}-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "database_memory" {
  alarm_name          = "${var.identifier}-freeable-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "512000000" # 512 MB in bytes
  alarm_description   = "This metric monitors RDS freeable memory"
  alarm_actions       = []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "database_storage" {
  alarm_name          = "${var.identifier}-free-storage-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "10000000000" # 10 GB in bytes
  alarm_description   = "This metric monitors RDS free storage space"
  alarm_actions       = []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "${var.identifier}-database-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "150"
  alarm_description   = "This metric monitors RDS database connections"
  alarm_actions       = []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}



