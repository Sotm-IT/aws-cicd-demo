const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// ルートハンドラー
app.get('/', (req, res) => {
  res.send('<h1>Hello from AWS CI/CD Demo!</h1>');
});

// ヘルスチェックエンドポイント
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', timestamp: new Date().toISOString() });
});

// サーバー起動
app.listen(port, () => {
  console.log(`App listening at http://localhost:${port}`);
  console.log(`Health check available at http://localhost:${port}/health`);
});
