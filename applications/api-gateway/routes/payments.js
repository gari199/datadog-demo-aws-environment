const express = require('express');
const axios = require('axios');
const router = express.Router();

const PAYMENT_SERVICE_URL = process.env.PAYMENT_SERVICE_URL || 'http://payment-service';

// Process payment
router.post('/process', async (req, res) => {
  try {
    console.log('Forwarding process payment request');
    const response = await axios.post(`${PAYMENT_SERVICE_URL}/process`, req.body, {
      timeout: 5000
    });
    res.status(response.status).json(response.data);
  } catch (error) {
    console.error('Error processing payment:', error.message);
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(503).json({
        error: 'Service Unavailable',
        message: 'Could not reach payment service'
      });
    }
  }
});

// Get payment by ID
router.get('/:id', async (req, res) => {
  try {
    console.log(`Forwarding get payment request for ID: ${req.params.id}`);
    const response = await axios.get(`${PAYMENT_SERVICE_URL}/payments/${req.params.id}`, {
      timeout: 5000
    });
    res.json(response.data);
  } catch (error) {
    console.error('Error getting payment:', error.message);
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(503).json({
        error: 'Service Unavailable',
        message: 'Could not reach payment service'
      });
    }
  }
});

// List payments
router.get('/', async (req, res) => {
  try {
    console.log('Forwarding list payments request');
    const response = await axios.get(`${PAYMENT_SERVICE_URL}/payments`, {
      timeout: 5000
    });
    res.json(response.data);
  } catch (error) {
    console.error('Error listing payments:', error.message);
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(503).json({
        error: 'Service Unavailable',
        message: 'Could not reach payment service'
      });
    }
  }
});

// Get payments by order ID
router.get('/order/:order_id', async (req, res) => {
  try {
    console.log(`Forwarding get payments by order ID: ${req.params.order_id}`);
    const response = await axios.get(`${PAYMENT_SERVICE_URL}/orders/${req.params.order_id}/payments`, {
      timeout: 5000
    });
    res.json(response.data);
  } catch (error) {
    console.error('Error getting payments by order:', error.message);
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(503).json({
        error: 'Service Unavailable',
        message: 'Could not reach payment service'
      });
    }
  }
});

module.exports = router;
