#!/bin/bash
echo "1. 로컬 DB 덤프 중..."
/opt/homebrew/opt/postgresql@15/bin/pg_dump -h localhost -U minbyeonghun situation > /tmp/situation_dump.sql
echo "덤프 완료!"

echo "2. Supabase로 업로드 중... (Session Pooler)"
export PGPASSWORD='Na080510!@mqnet'
/opt/homebrew/opt/postgresql@15/bin/psql \
  -h aws-1-ap-northeast-1.pooler.supabase.com \
  -p 5432 \
  -U postgres.xwvrjszdemxhszaqhqto \
  -d postgres \
  -f /tmp/situation_dump.sql
echo "마이그레이션 완료!"
