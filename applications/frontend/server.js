const express = require('express');
const path = require('path');
const cors = require('cors');
const axios = require('axios');

const app = express();

const API_GATEWAY_URL = process.env.API_GATEWAY_URL || 'http://api-gateway';

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    service: 'frontend',
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// API Gateway proxy endpoint for client-side calls
app.get('/api/config', (req, res) => {
  res.json({
    apiGatewayUrl: '' // Empty string means use relative URLs (same origin)
  });
});

// Proxy all /api requests to API Gateway
app.use('/api', async (req, res) => {
  try {
    const url = `${API_GATEWAY_URL}/api${req.url}`;
    console.log(`Proxying ${req.method} /api${req.url} to ${url}`);

    const response = await axios({
      method: req.method,
      url: url,
      data: req.body,
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 5000
    });

    res.status(response.status).json(response.data);
  } catch (error) {
    console.error('Proxy error:', error.message);
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(503).json({
        error: 'Service Unavailable',
        message: 'Could not reach API Gateway'
      });
    }
  }
});

// Serve index.html for all other routes (SPA)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Frontend server listening on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'production'}`);
  console.log(`API Gateway URL: ${process.env.API_GATEWAY_URL || 'http://api-gateway'}`);
});

module.exports = app;
