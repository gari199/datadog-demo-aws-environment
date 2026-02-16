# Order Service

Simple Flask-based order management service for e-commerce demo.

## Features

- Create orders
- Retrieve orders (with Redis caching)
- List orders (with pagination)
- Update order status
- PostgreSQL for persistence
- Redis for caching

## API Endpoints

```
GET  /health              - Health check
POST /orders              - Create new order
GET  /orders/:id          - Get order by ID
GET  /orders              - List all orders (paginated)
PUT  /orders/:id/status   - Update order status
```

## Environment Variables

```bash
DB_HOST=localhost          # PostgreSQL host
DB_PORT=5432              # PostgreSQL port
DB_NAME=ecommerce         # Database name
DB_USER=dbadmin           # Database user
DB_PASSWORD=password      # Database password
REDIS_HOST=localhost      # Redis host
REDIS_PORT=6379          # Redis port
PORT=5000                # Service port
```

## Local Development

### Install dependencies:
```bash
pip install -r requirements.txt
```

### Run locally:
```bash
export DB_HOST=localhost
export DB_PASSWORD=your_password
python app.py
```

### Test endpoints:
```bash
# Health check
curl http://localhost:5000/health

# Create order
curl -X POST http://localhost:5000/orders \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "product_name": "Laptop",
    "quantity": 1,
    "price": 999.99
  }'

# Get order
curl http://localhost:5000/orders/1

# List orders
curl http://localhost:5000/orders?page=1&per_page=10

# Update status
curl -X PUT http://localhost:5000/orders/1/status \
  -H "Content-Type: application/json" \
  -d '{"status": "completed"}'
```

## Docker Build

```bash
docker build -t order-service:latest .
docker run -p 5000:5000 \
  -e DB_HOST=your-rds-endpoint \
  -e DB_PASSWORD=password \
  -e REDIS_HOST=your-redis-endpoint \
  order-service:latest
```

## Kubernetes Deployment

See `kubernetes/apps/order-service/` for deployment manifests.
