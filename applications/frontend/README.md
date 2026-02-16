# Frontend Application

E-commerce frontend application with product browsing, shopping cart, and checkout functionality.

## Features

- Product catalog browsing
- Shopping cart with localStorage persistence
- Checkout flow with order and payment processing
- Responsive design
- Health check endpoint
- Vanilla JavaScript (no build step required)

## Architecture

- **Server**: Node.js/Express serving static files
- **Frontend**: Vanilla JavaScript SPA (no React compilation needed)
- **API**: Calls to API Gateway for products, orders, and payments

## API Endpoints

### Health Check
```bash
GET /health
```

### Config
```bash
GET /api/config  # Returns API Gateway URL
```

## Environment Variables

- `PORT` - Server port (default: 8080)
- `NODE_ENV` - Environment: development, production (default: production)
- `API_GATEWAY_URL` - API Gateway URL (default: http://api-gateway)

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
docker build --platform linux/amd64 -t gari199/frontend:latest .

# Push to Docker Hub
docker push gari199/frontend:latest
```

## Testing

```bash
# Open browser
open http://localhost:8080

# Test health check
curl http://localhost:8080/health

# Test config endpoint
curl http://localhost:8080/api/config
```

## User Flow

1. **Browse Products**: View all available products from the catalog
2. **Add to Cart**: Click "Add to Cart" to add items
3. **View Cart**: Click cart button in header to see items
4. **Checkout**: Click "Proceed to Checkout" to place order
5. **Order Processing**:
   - Creates order via Order Service
   - Processes payment via Payment Service
   - Displays success message

## Cart Persistence

- Cart items are saved to browser localStorage
- Cart persists across page refreshes
- Cart is cleared after successful checkout

## Future Enhancements (for Datadog integration)

- Real User Monitoring (RUM) with dd-rum
- Session Replay
- Error tracking
- Performance monitoring (Core Web Vitals)
- User journey tracking
- Custom RUM events
