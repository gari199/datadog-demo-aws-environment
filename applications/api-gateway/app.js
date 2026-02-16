const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const ordersRouter = require('./routes/orders');
const paymentsRouter = require('./routes/payments');
const productsRouter = require('./routes/products');

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    service: 'api-gateway',
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// API routes
app.use('/api/orders', ordersRouter);
app.use('/api/payments', paymentsRouter);
app.use('/api/products', productsRouter);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'E-commerce API Gateway',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      orders: '/api/orders',
      payments: '/api/payments',
      products: '/api/products'
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Cannot ${req.method} ${req.path}`
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`API Gateway listening on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'production'}`);
  console.log(`Order Service: ${process.env.ORDER_SERVICE_URL || 'http://order-service'}`);
  console.log(`Payment Service: ${process.env.PAYMENT_SERVICE_URL || 'http://payment-service'}`);
});

module.exports = app;
