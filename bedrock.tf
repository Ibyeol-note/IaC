# ==========================================
# AWS Bedrock IAM 설정
# ==========================================
# EC2 인스턴스가 Bedrock API를 호출할 수 있도록
# IAM 역할과 정책을 정의합니다.
# ==========================================

# IAM 역할: EC2가 Assume할 수 있는 역할
resource "aws_iam_role" "ec2_bedrock_role" {
  name               = "${var.project_name}-ec2-bedrock-role-${var.environment}"
  description        = "IAM role for EC2 to access AWS Bedrock"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-bedrock-role-${var.environment}"
  }
}

# IAM 정책: Bedrock InvokeModel 권한
resource "aws_iam_policy" "bedrock_invoke" {
  name        = "${var.project_name}-bedrock-invoke-${var.environment}"
  description = "Policy to allow invoking AWS Bedrock models"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          # Claude 3 Haiku 모델 (가성비 좋은 감정 분석)
          "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-3-haiku-20240307",
          "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-3-haiku-*",
          "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-3-*"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-bedrock-invoke-${var.environment}"
  }
}

# IAM 정책 연결: Bedrock 권한을 역할에 추가
resource "aws_iam_role_policy_attachment" "bedrock_invoke" {
  role       = aws_iam_role.ec2_bedrock_role.name
  policy_arn = aws_iam_policy.bedrock_invoke.arn
}

# 선택사항: CloudWatch Logs 권한 (로깅 필요 시)
resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.project_name}-cloudwatch-logs-${var.environment}"
  description = "Policy to allow writing logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/bedrock/*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-cloudwatch-logs-${var.environment}"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.ec2_bedrock_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}

# EC2 인스턴스 프로필: EC2에 IAM 역할을 연결하기 위한 리소스
resource "aws_iam_instance_profile" "ec2_bedrock" {
  name = "${var.project_name}-ec2-bedrock-profile-${var.environment}"
  role = aws_iam_role.ec2_bedrock_role.name

  tags = {
    Name = "${var.project_name}-ec2-bedrock-profile-${var.environment}"
  }
}

# ==========================================
# 개발용 IAM 사용자 (로컬 개발용, 선택사항)
# ==========================================
# 로컬 개발 환경에서 Bedrock을 테스트할 때 사용
# 프로덕션에서는 EC2 IAM 역할 사용 권장
# ==========================================

resource "aws_iam_user" "bedrock_dev" {
  count = var.create_dev_user ? 1 : 0
  name  = "${var.project_name}-bedrock-dev-${var.environment}"

  tags = {
    Name        = "${var.project_name}-bedrock-dev-${var.environment}"
    Description = "Developer user for local Bedrock testing"
  }
}

resource "aws_iam_user_policy_attachment" "bedrock_dev" {
  count      = var.create_dev_user ? 1 : 0
  user       = aws_iam_user.bedrock_dev[0].name
  policy_arn = aws_iam_policy.bedrock_invoke.arn
}

# 개발 사용자 Access Key (주의: 보안에 민감)
resource "aws_iam_access_key" "bedrock_dev" {
  count = var.create_dev_user ? 1 : 0
  user  = aws_iam_user.bedrock_dev[0].name
}

# ==========================================
# Outputs
# ==========================================

output "bedrock_iam_role_arn" {
  description = "ARN of the IAM role for Bedrock access"
  value       = aws_iam_role.ec2_bedrock_role.arn
}

output "bedrock_instance_profile_name" {
  description = "Name of the instance profile for EC2"
  value       = aws_iam_instance_profile.ec2_bedrock.name
}

output "bedrock_dev_access_key_id" {
  description = "Access Key ID for development user (if created)"
  value       = var.create_dev_user ? aws_iam_access_key.bedrock_dev[0].id : "Not created"
}

output "bedrock_dev_secret_access_key" {
  description = "Secret Access Key for development user (SENSITIVE)"
  value       = var.create_dev_user ? aws_iam_access_key.bedrock_dev[0].secret : "Not created"
  sensitive   = true
}
