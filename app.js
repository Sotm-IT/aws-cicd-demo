const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// リクエストロギングミドルウェア
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.originalUrl} ${res.statusCode} - ${duration}ms`);
  });
  next();
});

// エラーハンドリングミドルウェア
app.use((err, req, res, next) => {
  console.error('Application error:', err);
  res.status(500).json({ error: 'Something went wrong', message: err.message });
});

// ルートハンドラー
app.get('/', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>AWS CI/CD Demo</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
          h1 { color: #0066cc; }
          footer { margin-top: 40px; font-size: 0.8em; color: #666; }
        </style>
      </head>
      <body>
        <h1>Hello from AWS CI/CD Demo!</h1>
        <p>This application is deployed using AWS CI/CD Pipeline</p>
        <p>I love AWS!</p>
        <p><a href="/health">Check health status</a></p>
        <footer>Deployment time: ${new Date().toISOString()}</footer>
      </body>
    </html>
  `);
});

// ヘルスチェックエンドポイント
app.get('/health', (req, res) => {
  const healthData = {
    status: 'UP',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memoryUsage: process.memoryUsage(),
    environment: process.env.NODE_ENV || 'development'
  };

  res.status(200).json(healthData);
});

// 404ハンドラー
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found', path: req.originalUrl });
});

// サーバー起動
const server = app.listen(port, () => {
  console.log(`Application started at ${new Date().toISOString()}`);
  console.log(`Server listening at http://localhost:${port}`);
  console.log(`Health check available at http://localhost:${port}/health`);
});

// グレースフルシャットダウン
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
