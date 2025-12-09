# SSH Key Pair 생성 (TLS 프로바이더 사용)
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key-${var.environment}"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = {
    Name = "${var.project_name}-key-${var.environment}"
  }
}

# 프라이빗 키를 로컬 파일로 저장
resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/${var.project_name}-${var.environment}.pem"
  file_permission = "0400"
}

# 최신 Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 인스턴스
resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.ec2_instance_type

  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.main.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  # 서버 초기 설정 스크립트
  user_data = <<-EOF
    #!/bin/bash
    # 시스템 업데이트
    dnf update -y

    # Node.js 20 설치
    dnf install -y nodejs20 npm git

    # PM2 전역 설치
    npm install -g pm2

    # 앱 디렉토리 생성
    mkdir -p /home/ec2-user/app
    chown ec2-user:ec2-user /home/ec2-user/app
  EOF

  tags = {
    Name = "${var.project_name}-ec2-${var.environment}"
  }
}
