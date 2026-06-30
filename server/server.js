const express = require('express');
const { MongoClient } = require('mongodb');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;


// MongoDB 연결 설정
const MONGODB_URI = process.env.MONGODB_URI;
const DB_NAME = 'flutter_notifications';
const COLLECTION_NAME = 'notifications';

let db;
let notificationsCollection;

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB 연결
async function connectMongoDB() {
  try {
    const client = new MongoClient(MONGODB_URI);
    await client.connect();
    db = client.db(DB_NAME);
    notificationsCollection = db.collection(COLLECTION_NAME);
    
    // 인덱스 생성 (timestamp로 정렬 가능하도록)
    await notificationsCollection.createIndex({ timestamp: -1 });
    
    console.log('✓ Connected to MongoDB');
  } catch (error) {
    console.error('✗ MongoDB connection error:', error);
    process.exit(1);
  }
}

// 알림 저장 API
app.post('/api/notifications', async (req, res) => {
  try {
    const { title, text, package: pkg, timestamp, formattedTime } = req.body;

    if (!title || !text) {
      return res.status(400).json({ error: 'title and text are required' });
    }

    const notification = {
      title,
      text,
      package: pkg,
      timestamp: new Date(timestamp),
      formattedTime,
      savedAt: new Date(),
    };

    const result = await notificationsCollection.insertOne(notification);

    res.status(201).json({
      success: true,
      id: result.insertedId,
      message: 'Notification saved successfully',
    });
  } catch (error) {
    console.error('Error saving notification:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 모든 알림 조회 API
app.get('/api/notifications', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 50;
    const notifications = await notificationsCollection
      .find()
      .sort({ timestamp: -1 })
      .limit(limit)
      .toArray();

    res.json({
      success: true,
      count: notifications.length,
      notifications,
    });
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 특정 패키지의 알림 조회
app.get('/api/notifications/package/:packageName', async (req, res) => {
  try {
    const { packageName } = req.params;
    const notifications = await notificationsCollection
      .find({ package: packageName })
      .sort({ timestamp: -1 })
      .limit(50)
      .toArray();

    res.json({
      success: true,
      package: packageName,
      count: notifications.length,
      notifications,
    });
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 상태 확인 API
app.get('/api/health', (req, res) => {
  res.json({ status: 'Server is running' });
});

// 서버 시작
connectMongoDB().then(() => {
  app.listen(PORT, () => {
    console.log(`\n📱 Notification Server running on http://localhost:${PORT}`);
    console.log(`📊 POST   /api/notifications         - Save notification`);
    console.log(`📊 GET    /api/notifications         - Get all notifications`);
    console.log(`📊 GET    /api/notifications/package/:name - Get by package\n`);
  });
});
