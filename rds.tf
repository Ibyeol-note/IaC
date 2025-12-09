# RDS 서브넷 그룹
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group-${var.environment}"
  description = "Database subnet group for ${var.project_name}"
  subnet_ids  = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group-${var.environment}"
  }
}

# RDS PostgreSQL 인스턴스
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db-${var.environment}"

  # 엔진 설정
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = var.rds_instance_class
  allocated_storage    = 20
  max_allocated_storage = 100 # 자동 스케일링 최대값
  storage_type         = "gp3"
  storage_encrypted    = true

  # 데이터베이스 설정
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # 네트워크 설정
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  port                   = 5432

  # 백업 설정
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # 기타 설정
  multi_az               = false # PoC이므로 단일 AZ
  skip_final_snapshot    = true  # 개발 환경이므로 최종 스냅샷 스킵
  deletion_protection    = false # 개발 환경이므로 삭제 보호 해제
  copy_tags_to_snapshot  = true

  # 파라미터 그룹 (기본값 사용)
  parameter_group_name = "default.postgres15"

  tags = {
    Name = "${var.project_name}-db-${var.environment}"
  }
}
