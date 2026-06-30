const request = require('supertest');
const app = require('./app');

describe('API Tests', () => {
  test('GET / returns 200 OK', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.text).toContain('DevOps World');
  });

  test('GET /health returns 200 OK', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('OK');
  });

  test('GET /user/:id returns user id', async () => {
    const res = await request(app).get('/user/42');
    expect(res.statusCode).toBe(200);
    expect(res.text).toBe('User ID: 42');
  });

  test('POST /submit returns correctly', async () => {
    const res = await request(app).post('/submit').send({ data: 'test-value' });
    expect(res.statusCode).toBe(200);
    expect(res.text).toBe('Received: test-value');
  });

  test('POST /submit without data returns 400', async () => {
    const res = await request(app).post('/submit').send({});
    expect(res.statusCode).toBe(400);
  });

  test('GET /metrics returns observability data', async () => {
    const res = await request(app).get('/metrics');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('uptime');
    expect(res.body).toHaveProperty('memory');
  });
});
