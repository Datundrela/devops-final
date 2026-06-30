const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;
const ENV_NAME = process.env.APP_ENV || 'local';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => {
  res.status(200).send('Hello, DevOps World! My Pipeline is working!');
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    env: ENV_NAME,
    uptime: process.uptime(),
  });
});

app.get('/user/:id', (req, res) => {
  res.send(`User ID: ${req.params.id}`);
});

app.post('/submit', (req, res) => {
  const data = req.body.data;
  if (!data) return res.status(400).send('No data provided');
  res.send(`Received: ${data}`);
});

app.get('/metrics', (req, res) => {
  res.json({
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    env: ENV_NAME,
  });
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`SERVER_START: Application listening on port ${PORT} (${ENV_NAME})`);
  });
}

module.exports = app;
