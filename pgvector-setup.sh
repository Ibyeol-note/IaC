#!/bin/bash
# ==========================================
# PostgreSQL pgvector 확장 설치 스크립트
# ==========================================
# RDS 또는 EC2 PostgreSQL에 pgvector 확장 설치
# 사용법: ./pgvector-setup.sh
# ==========================================

set -e

echo "🚀 pgvector 확장 설치 시작..."

# 환경 변수 확인
if [ -z "$DB_HOST" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ]; then
    echo "❌ 환경 변수가 설정되지 않았습니다."
    echo "다음 환경 변수를 설정해주세요:"
    echo "  export DB_HOST=your-rds-endpoint"
    echo "  export DB_NAME=ibyeol_note"
    echo "  export DB_USER=postgres"
    echo "  export PGPASSWORD=your-password"
    exit 1
fi

echo "📦 데이터베이스 연결 정보:"
echo "  Host: $DB_HOST"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"

# pgvector 확장 생성
echo ""
echo "🔧 pgvector 확장 생성 중..."
PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS vector;"

# 확인
echo ""
echo "✅ pgvector 설치 확인..."
PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "\dx vector"

echo ""
echo "✅ pgvector 확장 설치 완료!"
echo ""
echo "📝 다음 단계:"
echo "1. 애플리케이션 배포"
echo "2. MikroORM이 자동으로 embedding 컬럼 생성"
echo "3. 유사도 검색 기능 사용 가능"
