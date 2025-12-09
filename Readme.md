# 이별노트 인프라 (Terraform)

AWS EC2와 RDS를 프로비저닝하는 Terraform 설정입니다.

## 인프라 구성

| 리소스 | 사양 | 설명 |
|--------|------|------|
| VPC | 10.0.0.0/16 | 퍼블릭/프라이빗 서브넷 |
| EC2 | t3.micro | NestJS 애플리케이션 서버 |
| RDS | db.t3.micro, PostgreSQL 15 | 데이터베이스 |

## 사전 요구사항

1. [Terraform](https://www.terraform.io/downloads) 설치 (v1.0.0+)
2. AWS CLI 설치 및 설정
   ```bash
   aws configure
   # AWS Access Key ID, Secret Access Key, Region 입력
   ```

## 사용 방법

### 1. 변수 파일 생성

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

### 2. terraform.tfvars 수정

```hcl
db_password      = "YOUR_SECURE_PASSWORD"  # 안전한 비밀번호로 변경!
allowed_ssh_cidr = "YOUR_IP/32"            # 본인 IP로 제한 권장
```

> 💡 본인 IP 확인: https://checkip.amazonaws.com

### 3. Terraform 실행

```bash
# 초기화
terraform init

# 계획 확인
terraform plan

# 적용
terraform apply
```

### 4. 출력 확인

```bash
terraform output
```

주요 출력값:
- `ec2_public_ip`: EC2 퍼블릭 IP
- `rds_endpoint`: RDS 접속 엔드포인트
- `ssh_command`: SSH 접속 명령어

## EC2 접속

```bash
# Terraform이 자동으로 키 파일을 생성합니다
ssh -i ibyeol-note-dev.pem ec2-user@<EC2_PUBLIC_IP>
```

## 애플리케이션 배포

```bash
# EC2 접속 후
cd /home/ec2-user/app

# 코드 클론 (또는 SCP로 업로드)
git clone <YOUR_REPO_URL> .

# 의존성 설치
cd server
npm install

# 환경 변수 설정
cat > .env.production << EOF
DB_HOST=<RDS_HOST>
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=<YOUR_PASSWORD>
DB_NAME=ibyeol_note
JWT_SECRET=<YOUR_JWT_SECRET>
JWT_EXPIRES_IN=7d
EOF

# 빌드 및 실행
npm run build
pm2 start dist/main.js --name ibyeol-note
```

## 리소스 삭제

```bash
terraform destroy
```

## 비용 참고

- EC2 t3.micro: Free Tier 대상 (12개월)
- RDS db.t3.micro: Free Tier 대상 (12개월)
- 예상 월 비용 (Free Tier 이후): ~$25-30

## 보안 참고사항

- `terraform.tfvars`와 `.pem` 파일은 절대 Git에 커밋하지 마세요
- SSH 접근은 본인 IP로 제한하세요
- RDS는 EC2에서만 접근 가능하도록 설정되어 있습니다
