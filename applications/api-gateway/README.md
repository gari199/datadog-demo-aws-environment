# API Gateway

API Gateway service for e-commerce microservices architecture. Routes requests between frontend and backend services (Order Service and Payment Service).

## Features

- Request routing and proxying
- CORS support
- Security headers (Helmet)
- Request logging (Morgan)
- Error handling
- Health check endpoint
- Mock product catalog

## Architecture

The API Gateway acts as a single entry point for the frontend, routing requests to:
- **Order Service** - Order management (PostgreSQL + Redis)
- **Payment Service** - Payment processing (in-memory)
- **Products** - Mock product catalog (in-memory)

## API Endpoints

### Health Check
```bash
GET /health
```

### Orders
```bash
POST /api/orders              # Create order
GET  /api/orders              # List orders
GET  /api/orders/:id          # Get order by ID
```

### Payments
```bash
POST /api/payments/process           # Process payment
GET  /api/payments                   # List payments
GET  /api/payments/:id               # Get payment by ID
GET  /api/payments/order/:order_id   # Get payments for order
```

### Products
```bash
GET /api/products                    # List all products
GET /api/products/:id                # Get product by ID
GET /api/products/meta/categories    # Get categories
```

## Environment Variables

- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment: development, production (default: production)
- `ORDER_SERVICE_URL` - Order service URL (default: http://order-service)
- `PAYMENT_SERVICE_URL` - Payment service URL (default: http://payment-service)

## Local Development

```bash
# Install dependencies
npm install

# Run in development mode
npm run dev

# Run in production mode
npm start
```

## Docker Build

```bash
# Build for AMD64 (EKS compatibility)
docker build --platform linux/amd64 -t gari199/api-gateway:latest .

# Push to Docker Hub
docker push gari199/api-gateway:latest
```

## Testing

```bash
# Health check
curl http://localhost:3000/health

# List products
curl http://localhost:3000/api/products

# Create order
curl -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 123,
    "product_name": "Laptop Computer",
    "quantity": 1,
    "price": 1299.99
  }'

# Process payment
curl -X POST http://localhost:3000/api/payments/process \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "order-123",
    "amount": 1299.99,
    "currency": "USD",
    "method": "credit_card",
    "card_number": "4532015112830366",
    "card_expiry": "12/25",
    "card_cvv": "123"
  }'
```

## Service Dependencies

The API Gateway requires the following services to be running:
- **Order Service** (http://order-service:80 in Kubernetes)
- **Payment Service** (http://payment-service:80 in Kubernetes)

## Future Enhancements (for Datadog integration)

- APM tracing with dd-trace
- Distributed tracing across services
- Custom metrics for API calls
- Rate limiting and circuit breakers
- Request/response logging correlation
