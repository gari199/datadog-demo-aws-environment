# Legacy Admin App

Traditional VM-based admin dashboard for viewing orders. Demonstrates legacy infrastructure monitoring patterns compared to containerized applications.

## Features

- Admin dashboard with order statistics
- Real-time order viewing from PostgreSQL
- Direct database connection (no API Gateway)
- Traditional VM deployment with systemd
- Auto-refresh every 30 seconds

## Architecture

- **Platform**: EC2 VM (traditional infrastructure)
- **Language**: Python 3 + Flask
- **Database**: Direct connection to PostgreSQL RDS
- **Process Manager**: systemd
- **Port**: 5002

## Differences from Microservices

| Aspect | Legacy Admin | Microservices |
|--------|--------------|---------------|
| Deployment | Manual to EC2 VM | Automated to Kubernetes |
| Scaling | Vertical (bigger VM) | Horizontal (more pods) |
| Updates | SSH and restart service | Rolling deployment |
| Monitoring | Traditional host metrics | Container metrics |
| Database Access | Direct connection | Through Order Service |

## API Endpoints

### Dashboard
```bash
GET /       # Admin dashboard UI
```

### Health Check
```bash
GET /health
```

### Orders API
```bash
GET /api/orders     # Get all orders
GET /api/stats      # Get order statistics
```

## Environment Variables

- `DB_HOST` - PostgreSQL host (default: RDS endpoint)
- `DB_PORT` - PostgreSQL port (default: 5432)
- `DB_NAME` - Database name (default: ecommerce)
- `DB_USER` - Database user (default: dbadmin)
- `DB_PASSWORD` - Database password (default: password)
- `PORT` - Application port (default: 5002)

## Local Development

```bash
# Install dependencies
pip3 install -r requirements.txt

# Set environment variables
export DB_HOST=datadog-demo-postgres.c7ckk2qsyz0a.eu-central-1.rds.amazonaws.com
export DB_PASSWORD=password

# Run the application
python3 app.py
```

## Deployment to EC2

```bash
# Make deploy script executable
chmod +x deploy.sh

# Deploy to EC2 VM1
./deploy.sh
```

The deployment script will:
1. Copy application files to EC2
2. Install Python dependencies
3. Set up systemd service
4. Start the application

## Access the Dashboard

The admin dashboard will be available at:
```
http://10.0.10.12:5002
```

## Service Management

```bash
# View status
sudo systemctl status admin-app

# View logs
sudo journalctl -u admin-app -f

# Restart service
sudo systemctl restart admin-app

# Stop service
sudo systemctl stop admin-app

# Start service
sudo systemctl start admin-app
```

## Database Queries

The application executes the following queries:

### Get all orders
```sql
SELECT id, user_id, product_name, quantity, price, total, status,
       created_at, updated_at
FROM orders
ORDER BY created_at DESC
```

### Get statistics
```sql
-- Total orders
SELECT COUNT(*) FROM orders;

-- Total revenue
SELECT SUM(total) FROM orders;

-- Orders by status
SELECT status, COUNT(*) FROM orders GROUP BY status;

-- Recent orders (24h)
SELECT COUNT(*) FROM orders
WHERE created_at > NOW() - INTERVAL '24 hours';
```

## Testing

```bash
# Health check
curl http://10.0.10.12:5002/health

# Get orders
curl http://10.0.10.12:5002/api/orders

# Get stats
curl http://10.0.10.12:5002/api/stats

# View dashboard (requires browser)
open http://10.0.10.12:5002
```

## Future Enhancements (for Datadog integration)

- APM tracing with dd-trace
- Database query monitoring
- Host-level metrics collection
- Custom metrics for admin actions
- Log aggregation and correlation
