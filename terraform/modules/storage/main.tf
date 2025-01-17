variable "environment" {
  description = "Environment name"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

resource "aws_s3_bucket" "app" {
  bucket = "${var.environment}-app-storage-${random_id.bucket_suffix.dec}"

  tags = merge(var.tags, {
    Name        = "${var.environment}-app-storage"
    Environment = var.environment
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_elasticache_cluster" "app" {
  cluster_id           = "${var.environment}-cache"
  engine              = "redis"
  node_type           = "cache.t3.micro"
  num_cache_nodes     = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                = 6379

  tags = merge(var.tags, {
    Name        = "${var.environment}-cache"
    Environment = var.environment
  })
}

resource "aws_db_subnet_group" "app" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-rds-sg"
    Environment = var.environment
  })
}

variable "subnet_ids" {
  description = "Subnet IDs for RDS"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for RDS ingress"
  type        = string
}

resource "aws_db_instance" "app" {
  identifier             = "${var.environment}-app-db"
  engine                 = "postgres"
  engine_version         = "15.3"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.app.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = false
  skip_final_snapshot    = true
  backup_retention_period = var.backup_retention_days
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  tags = merge(var.tags, {
    Name        = "${var.environment}-app-db"
    Environment = var.environment
  })
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

output "s3_bucket_name" {
  value = aws_s3_bucket.app.id
}

output "cache_endpoint" {
  value = aws_elasticache_cluster.app.cache_nodes[0].address
}

output "db_endpoint" {
  value = aws_db_instance.app.endpoint
}

output "db_port" {
  value = aws_db_instance.app.port
}
