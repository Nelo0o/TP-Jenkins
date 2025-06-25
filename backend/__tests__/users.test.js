const request = require('supertest');
const express = require('express');

let app;

beforeAll(() => {
  app = express();
  
  app.get('/users-list', (req, res) => {
    res.send({
      users: [
        {
          id: 1,
          name: 'John Doe',
          email: 'john.doe@example.com',
        },
        {
          id: 2,
          name: 'Jane Doe',
          email: 'jane.doe@example.com',
        },
      ],
    });
  });
});

describe('Users API', () => {
  it('GET /users-list - should return list of users', async () => {
    const response = await request(app).get('/users-list');
    
    expect(response.statusCode).toBe(200);
    
    expect(response.body).toHaveProperty('users');
    expect(Array.isArray(response.body.users)).toBe(true);
    
    expect(response.body.users.length).toBe(2);
    
    expect(response.body.users[0]).toEqual({
      id: 1,
      name: 'John Doe',
      email: 'john.doe@example.com',
    });
  });
});
