# Flutter + MongoDB 알림 저장 시스템

## 전체 구조
```
Flutter 앱 (알림 수신) 
    ↓
HTTP POST 요청 (타임스탬프 포함)
    ↓
Node.js Express 서버
    ↓
MongoDB (알림 저장)
```

## 설치 방법

### 1. MongoDB 설치 및 실행

**Windows에서 MongoDB 설치:**
```powershell
# Chocolatey 사용 (권장)
choco install mongodb-community

# 또는 다운로드: https://www.mongodb.com/try/download/community
```

**MongoDB 실행:**
```powershell
# 기본 포트 27017에서 실행
mongod
```

**또는 MongoDB Atlas (클라우드) 사용:**
- https://www.mongodb.com/cloud/atlas 가입
- Cluster 생성
- Connection string 복사
- `.env` 파일의 MONGODB_URI 업데이트

### 2. Node.js 서버 설치 및 실행

```powershell
# 서버 디렉토리로 이동
cd C:\Users\sun01\Desktop\flutter_application_1\server

# 의존성 설치
npm install

# 서버 실행
npm start

# 또는 개발 모드 (자동 재시작)
npm run dev
```

**예상 출력:**
```
✓ Connected to MongoDB

📱 Notification Server running on http://localhost:3000
📊 POST   /api/notifications         - Save notification
📊 GET    /api/notifications         - Get all notifications
📊 GET    /api/notifications/package/:name - Get by package
```

### 3. Flutter 앱 빌드 및 실행

```powershell
# Flutter 의존성 설치
cd C:\Users\sun01\Desktop\flutter_application_1
flutter pub get

# APK 빌드
flutter build apk --release

# 또는 에뮬레이터/기기에서 실행
flutter run
```

## MongoDB 데이터 구조

**저장되는 데이터 형식:**
```json
{
  "_id": ObjectId("..."),
  "title": "카카오톡",
  "text": "새로운 메시지가 도착했습니다",
  "package": "com.kakao.talk",
  "timestamp": "2026-06-30T15:30:45.123Z",
  "formattedTime": "2026-06-30 15:30:45",
  "savedAt": "2026-06-30T15:30:46.456Z"
}
```

## API 사용 예시

### 1. 알림 저장 (POST)
```bash
curl -X POST http://localhost:3000/api/notifications \
  -H "Content-Type: application/json" \
  -d '{
    "title": "카카오톡",
    "text": "새로운 메시지",
    "package": "com.kakao.talk",
    "timestamp": "2026-06-30T15:30:45.123Z",
    "formattedTime": "2026-06-30 15:30:45"
  }'
```

### 2. 모든 알림 조회 (GET)
```bash
curl http://localhost:3000/api/notifications?limit=50
```

### 3. 특정 패키지 알림 조회
```bash
curl http://localhost:3000/api/notifications/package/com.kakao.talk
```

## MongoDB 데이터 확인

**MongoDB Compass 사용 (GUI):**
1. https://www.mongodb.com/products/tools/compass 다운로드
2. Connection String 입력: `mongodb://localhost:27017`
3. Database: `flutter_notifications`
4. Collection: `notifications` 에서 데이터 확인

**또는 CLI 사용:**
```powershell
mongo
> use flutter_notifications
> db.notifications.find().pretty()
```

## 주의사항

1. **로컬 테스트 시**: 안드로이드 에뮬레이터에서 `10.0.2.2:3000` 주소 사용
2. **실기기 테스트 시**: PC의 실제 IP 주소 사용 (예: `192.168.x.x:3000`)
3. **프로덕션**: MongoDB Atlas 클라우드 사용 권장

## 문제 해결

**서버가 시작되지 않음:**
```powershell
# MongoDB 실행 확인
Get-Process mongod

# 포트 3000 확인
netstat -ano | findstr :3000

# 포트 변경 필요시 server.js의 PORT 수정
```

**MongoDB 연결 실패:**
```powershell
# MongoDB 상태 확인
net start MongoDB

# 또는 PowerShell (관리자 권한)
Start-Service MongoDB
```

## 다음 단계

- 카카오톡 알림뿐 아니라 다른 앱 알림도 추가 저장 가능
- 웹 대시보드 추가: React/Vue로 알림 시각화
- 알림 필터링/검색 기능 추가
- Push notification 알림 전송 기능 추가
