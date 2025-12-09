# EC2 퍼블릭 IP
output "ec2_public_ip" {
  description = "EC2 인스턴스의 퍼블릭 IP 주소"
  value       = aws_instance.app.public_ip
}

# EC2 퍼블릭 DNS
output "ec2_public_dns" {
  description = "EC2 인스턴스의 퍼블릭 DNS"
  value       = aws_instance.app.public_dns
}

# SSH 접속 명령어
output "ssh_command" {
  description = "EC2 SSH 접속 명령어"
  value       = "ssh -i ${path.module}/${var.project_name}-${var.environment}.pem ec2-user@${aws_instance.app.public_ip}"
}

# 프라이빗 키 파일 경로
output "private_key_path" {
  description = "생성된 SSH 프라이빗 키 파일 경로"
  value       = local_file.private_key.filename
}

# RDS 엔드포인트
output "rds_endpoint" {
  description = "RDS 데이터베이스 엔드포인트"
  value       = aws_db_instance.main.endpoint
}

# RDS 호스트 (포트 제외)
output "rds_host" {
  description = "RDS 데이터베이스 호스트"
  value       = aws_db_instance.main.address
}

# RDS 포트
output "rds_port" {
  description = "RDS 데이터베이스 포트"
  value       = aws_db_instance.main.port
}

# RDS 데이터베이스 이름
output "rds_database_name" {
  description = "RDS 데이터베이스 이름"
  value       = aws_db_instance.main.db_name
}

# 애플리케이션 URL
output "app_url" {
  description = "애플리케이션 URL (포트 3000)"
  value       = "http://${aws_instance.app.public_ip}:3000"
}

# 환경 변수 형태로 DB 접속 정보 출력
output "env_database_url" {
  description = "환경 변수용 데이터베이스 URL"
  value       = "DB_HOST=${aws_db_instance.main.address}\nDB_PORT=${aws_db_instance.main.port}\nDB_NAME=${aws_db_instance.main.db_name}\nDB_USER=${var.db_username}"
  sensitive   = false
}
