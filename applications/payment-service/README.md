# Payment Service

Mock payment processing service built with Go and Gin framework.

## Features

- Mock payment processing (credit card, debit card, PayPal)
- In-memory payment storage
- Payment status tracking
- RESTful API endpoints
- Health check endpoint

## API Endpoints

### Health Check
```bash
GET /health
```

### Process Payment
```bash
POST /process
Content-Type: application/json

{
  "order_id": "123",
  "amount": 99.99,
  "currency": "USD",
  "method": "credit_card",
  "card_number": "4532015112830366",
  "card_expiry": "12/25",
  "card_cvv": "123"
}
```

### Get Payment by ID
```bash
GET /payments/:id
```

### List All Payments
```bash
GET /payments
```

### Get Payments by Order ID
```bash
GET /orders/:order_id/payments
```

## Environment Variables

- `PORT` - Server port (default: 5001)
- `GIN_MODE` - Gin mode: debug, release (default: release)

## Local Development

```bash
# Install dependencies
go mod download

# Run the service
go run main.go

# Or build and run
go build -o payment-service
./payment-service
```

## Docker Build

```bash
# Build for AMD64 (EKS compatibility)
docker build --platform linux/amd64 -t gari199/payment-service:latest .

# Push to Docker Hub
docker push gari199/payment-service:latest
```

## Testing

```bash
# Health check
curl http://localhost:5001/health

# Process payment
curl -X POST http://localhost:5001/process \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "order-123",
    "amount": 99.99,
    "currency": "USD",
    "method": "credit_card",
    "card_number": "4532015112830366",
    "card_expiry": "12/25",
    "card_cvv": "123"
  }'

# Get payment by ID
curl http://localhost:5001/payments/{payment_id}

# List all payments
curl http://localhost:5001/payments

# Get payments for an order
curl http://localhost:5001/orders/order-123/payments
```

## Mock Payment Behavior

- **Success Rate**: ~90% of payments succeed
- **Amount Validation**: Payments over $10,000 are rejected
- **Test Card**: Card number `4111111111111111` is always rejected
- **Processing Delay**: 100ms simulated processing time
- **Card Masking**: Only last 4 digits stored

## Future Enhancements (for Datadog integration)

- APM tracing with dd-trace-go
- Security monitoring (ASM) for payment data
- Custom metrics for payment processing
- Distributed tracing across services
