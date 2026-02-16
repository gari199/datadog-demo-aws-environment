const express = require('express');
const axios = require('axios');
const router = express.Router();

const ORDER_SERVICE_URL = process.env.ORDER_SERVICE_URL || 'http://order-service';

// Create order
router.post('/', async (req, res) => {
  try {
    console.log('Forwarding create order request to order service');
    const response = await axios.post(`${ORDER_SERVICE_URL}/orders`, req.body, {
      timeout: 5000
    });
    res.status(response.status).json(response.data);
  } catch (error) {
    console.error('Error creating order:', error.message);
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(503).json({
        error: 'Service Unavailable',
        message: 'Could not reach order service'
      });
    }
  }
});

// Get order by ID
router.get('/:id', async (req, res) => {
  try {
    console.log(`Forwarding get order request for ID: ${req.params.id}`);
    const response = await axios.get(`${ORDER_SERVICE_URL}/orders/${req.params.id}`, {
      timeout: 5000
    });
    res.json(response.data);
  } catch (error) {
    console.error('Error getting order:', error.message);
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(503).json({
        error: 'Service Unavailable',
        message: 'Could not reach order service'
      });
    }
  }
});

// List orders
router.get('/', async (req, res) => {
  try {
    console.log('Forwarding list orders request');
    const response = await axios.get(`${ORDER_SERVICE_URL}/orders`, {
      params: req.query,
      timeout: 5000
    });
    res.json(response.data);
  } catch (error) {
    console.error('Error listing orders:', error.message);
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(503).json({
        error: 'Service Unavailable',
        message: 'Could not reach order service'
      });
    }
  }
});

module.exports = router;
