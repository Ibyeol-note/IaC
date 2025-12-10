# AWS Region
variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

# 환경
variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# 프로젝트 이름
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "ibyeol-note"
}

# EC2 인스턴스 타입
variable "ec2_instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

# RDS 인스턴스 타입
variable "rds_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t2.micro"
}

# RDS 데이터베이스 이름
variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
  default     = "ibyeol_note"
}

# RDS 마스터 유저
variable "db_username" {
  description = "데이터베이스 마스터 유저 이름"
  type        = string
  default     = "postgres"
}

# RDS 마스터 패스워드
variable "db_password" {
  description = "데이터베이스 마스터 패스워드"
  type        = string
  sensitive   = true
}

# SSH 허용 IP (본인 IP로 설정 권장)
variable "allowed_ssh_cidr" {
  description = "SSH 접속을 허용할 CIDR 블록 (예: 본인 IP/32)"
  type        = string
  default     = "0.0.0.0/0" # 보안상 본인 IP로 제한 권장
}
