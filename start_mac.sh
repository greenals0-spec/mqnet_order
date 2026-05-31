#!/bin/bash
# SITUATION 프로젝트 Mac 자동 실행 스크립트

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "========================================"
echo "  SITUATION PRO - Mac 자동 실행"
echo "========================================"
echo ""

# Homebrew 확인
if ! command -v brew &>/dev/null; then
  echo "❌ Homebrew가 없습니다. 설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "✅ Homebrew OK"
fi

# Mosquitto 확인 및 설치
if ! command -v mosquitto &>/dev/null; then
  echo "📦 Mosquitto 설치 중..."
  brew install mosquitto
else
  echo "✅ Mosquitto OK"
fi

# PostgreSQL 확인
if ! command -v psql &>/dev/null; then
  echo "📦 PostgreSQL 설치 중..."
  brew install postgresql@15
  brew services start postgresql@15
  echo 'export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"' >> ~/.zprofile
  export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
else
  echo "✅ PostgreSQL OK"
fi

# Node.js 확인
if ! command -v node &>/dev/null; then
  echo "📦 Node.js 설치 중..."
  brew install node
else
  echo "✅ Node.js OK"
fi

# Python venv 생성 및 패키지 설치
echo ""
echo "[1/4] Python 가상환경 설정..."
cd "$BASE_DIR"
if [ ! -d "venv" ]; then
  python3 -m venv venv
  echo "venv 생성 완료"
fi
source venv/bin/activate
pip install -q -r requirements.txt
echo "✅ Python 패키지 설치 완료"

# 프론트엔드 패키지 설치
echo ""
echo "[2/4] 프론트엔드 패키지 설치..."
cd "$BASE_DIR/situation-room"
if [ ! -d "node_modules" ]; then
  npm install
fi
echo "✅ npm 패키지 설치 완료"

# MQTT 브로커 실행 (백그라운드)
echo ""
echo "[3/4] MQTT 브로커 시작..."
pkill -f mosquitto 2>/dev/null
sleep 1
mosquitto -c "$BASE_DIR/mosquitto.conf" &
MQTT_PID=$!
echo "✅ MQTT 브로커 실행 중 (PID: $MQTT_PID)"
sleep 2

# 백엔드 실행 (새 터미널 탭)
echo ""
echo "[4/4] 서버 시작..."

osascript <<EOF
tell application "Terminal"
  activate
  -- 백엔드 탭
  tell application "System Events" to keystroke "t" using command down
  delay 0.5
  do script "cd '$BASE_DIR/situation-backend' && source '../venv/bin/activate' && python -m uvicorn session.main:app --reload --host 0.0.0.0 --port 8000" in front window
  delay 1
  -- 프론트엔드 탭
  tell application "System Events" to keystroke "t" using command down
  delay 0.5
  do script "cd '$BASE_DIR/situation-room' && npm run dev" in front window
end tell
EOF

echo ""
echo "========================================"
echo "  🚀 실행 완료!"
echo ""
echo "  백엔드  : http://localhost:8000"
echo "  API문서 : http://localhost:8000/docs"
echo "  프론트  : http://localhost:5173"
echo "========================================"
echo ""
echo "브라우저에서 http://localhost:5173 을 열어보세요."
open "http://localhost:5173"
