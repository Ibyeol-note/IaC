# 이별노트 인프라 (Terraform)

AWS EC2와 RDS를 프로비저닝하는 Terraform 설정입니다.

## 인프라 구성

| 리소스 | 사양 | 설명 |
|--------|------|------|
| VPC | 10.0.0.0/16 | 퍼블릭/프라이빗 서브넷 |
| EC2 | t3.micro | NestJS 애플리케이션 서버 |
| RDS | db.t3.micro, PostgreSQL 15 | 데이터베이스 |
| **IAM Role** | Bedrock 접근 권한 | **EC2가 AWS Bedrock 호출** |
| **Bedrock** | Claude 3.5 Sonnet | **AI 감정 분석** |

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
create_dev_user  = false                   # 로컬 개발용 IAM 사용자 (선택)
```

> 💡 본인 IP 확인: https://checkip.amazonaws.com
> 💡 `create_dev_user = true`로 설정하면 로컬 개발용 AWS Access Key 생성

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
- `bedrock_iam_role_arn`: Bedrock 접근 IAM 역할 ARN
- `bedrock_dev_access_key_id`: 개발용 Access Key (선택사항)

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

# AWS Bedrock (EC2 IAM 역할 사용 - 자격 증명 불필요)
AWS_REGION=ap-northeast-2
BEDROCK_MODEL_ID=anthropic.claude-3-5-sonnet-20241022-v2:0
BEDROCK_MAX_RETRIES=2
BEDROCK_TIMEOUT=10000
EOF

# 빌드 및 실행
npm run build
pm2 start dist/main.js --name ibyeol-note
```

## 리소스 삭제

```bash
terraform destroy
```

## AWS Bedrock 설정

### 1. Bedrock 모델 액세스 활성화

**Terraform 적용 전 필수:**

1. AWS Console → Bedrock 서비스 이동
2. **Model access** 메뉴 클릭
3. **Anthropic Claude 3.5 Sonnet** 모델 선택
4. **Request model access** 클릭
5. 승인 대기 (수 분~수 시간)

### 2. EC2에서 Bedrock 사용

Terraform이 자동으로 IAM 역할을 EC2에 연결하므로, **별도의 AWS 자격 증명이 필요 없습니다!**

EC2에서 애플리케이션 실행 시 자동으로 Bedrock API 호출 가능합니다.

### 3. 로컬 개발 환경에서 Bedrock 사용 (선택사항)

**방법 1: IAM 사용자 생성 (Terraform)**

```hcl
# terraform.tfvars에 추가
create_dev_user = true
```

```bash
terraform apply

# Access Key 확인
terraform output bedrock_dev_access_key_id
terraform output bedrock_dev_secret_access_key
```

**.env.development에 추가:**
```env
AWS_ACCESS_KEY_ID=<terraform output에서 확인>
AWS_SECRET_ACCESS_KEY=<terraform output에서 확인>
AWS_REGION=ap-northeast-2
```

**방법 2: AWS CLI 프로필 사용**

```bash
aws configure --profile ibyeolnote
# Access Key, Secret Key 입력
```

애플리케이션에서 자동으로 프로필 사용

## 비용 참고

- EC2 t3.micro: Free Tier 대상 (12개월)
- RDS db.t3.micro: Free Tier 대상 (12개월)
- **Bedrock (Claude 3.5 Sonnet)**: 일기 1건당 약 $0.006 (8원)
  - 월 1,000건: $6 (8,000원)
  - 월 10,000건: $60 (80,000원)
- 예상 월 비용 (Free Tier 이후): ~$25-30 + Bedrock 사용량

## 보안 참고사항

- `terraform.tfvars`와 `.pem` 파일은 절대 Git에 커밋하지 마세요
- SSH 접근은 본인 IP로 제한하세요
- RDS는 EC2에서만 접근 가능하도록 설정되어 있습니다
- **프로덕션에서는 IAM 역할 사용, 로컬에서만 Access Key 사용**
- Bedrock IAM 정책은 최소 권한 원칙 적용 (InvokeModel만)

## 파일 구조

```
IaC/
├── main.tf              # Terraform 기본 설정
├── vpc.tf               # VPC, 서브넷, 라우팅
├── ec2.tf               # EC2 인스턴스 (IAM 역할 포함)
├── rds.tf               # RDS PostgreSQL
├── security_groups.tf   # 보안 그룹
├── bedrock.tf           # 🆕 Bedrock IAM 역할 및 정책
├── variables.tf         # 변수 정의
├── outputs.tf           # 출력값
├── terraform.tfvars     # 변수 값 (Git 제외)
└── README.md            # 이 파일
```

## 트러블슈팅

### Bedrock "Model not found" 에러

**증상:**
```
❌ AWS Bedrock 분석 실패: Model not found
```

**해결:**
1. AWS Console → Bedrock → Model access 확인
2. Claude 3.5 Sonnet 모델 액세스 승인 여부 확인
3. 리전이 올바른지 확인 (ap-northeast-2 또는 us-east-1)

### Bedrock "Access Denied" 에러

**증상:**
```
❌ AWS Bedrock 분석 실패: AccessDeniedException
```

**해결:**
1. EC2 인스턴스에 IAM 역할이 연결되어 있는지 확인:
   ```bash
   aws sts get-caller-identity
   ```
2. Terraform 재적용:
   ```bash
   terraform apply
   ```

### 로컬에서 Bedrock 호출 안 됨

**해결:**
1. `.env.development`에 AWS 자격 증명 확인
2. 또는 `create_dev_user = true`로 IAM 사용자 생성
3. AWS CLI 프로필 설정 확인
