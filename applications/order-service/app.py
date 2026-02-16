"""
Order Service - Simple Flask API for E-commerce Orders
Handles order creation, retrieval, and management
Connects to PostgreSQL and Redis
"""

from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import os
import redis
import json
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)

# Database configuration
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME', 'ecommerce')
DB_USER = os.getenv('DB_USER', 'dbadmin')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'password')

app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Initialize database
db = SQLAlchemy(app)

# Redis configuration
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', '6379'))

try:
    redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
    redis_client.ping()
    logger.info(f"Connected to Redis at {REDIS_HOST}:{REDIS_PORT}")
except Exception as e:
    logger.warning(f"Could not connect to Redis: {e}")
    redis_client = None


# Order Model
class Order(db.Model):
    __tablename__ = 'orders'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, nullable=False)
    product_name = db.Column(db.String(200), nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
    price = db.Column(db.Float, nullable=False)
    total = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(50), default='pending')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'product_name': self.product_name,
            'quantity': self.quantity,
            'price': self.price,
            'total': self.total,
            'status': self.status,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


# Routes

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'service': 'order-service'}), 200


@app.route('/orders', methods=['POST'])
def create_order():
    """Create a new order"""
    try:
        data = request.get_json()

        # Validate input
        if not data or not all(k in data for k in ['user_id', 'product_name', 'quantity', 'price']):
            return jsonify({'error': 'Missing required fields'}), 400

        # Calculate total
        total = data['quantity'] * data['price']

        # Create order
        order = Order(
            user_id=data['user_id'],
            product_name=data['product_name'],
            quantity=data['quantity'],
            price=data['price'],
            total=total,
            status='pending'
        )

        db.session.add(order)
        db.session.commit()

        logger.info(f"Order created: {order.id}")

        # Cache in Redis
        if redis_client:
            cache_key = f'order:{order.id}'
            redis_client.setex(cache_key, 300, json.dumps(order.to_dict()))  # Cache for 5 minutes
            logger.info(f"Order cached: {cache_key}")

        return jsonify(order.to_dict()), 201

    except Exception as e:
        logger.error(f"Error creating order: {e}")
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@app.route('/orders/<int:order_id>', methods=['GET'])
def get_order(order_id):
    """Get order by ID - check cache first"""
    try:
        # Try cache first
        if redis_client:
            cache_key = f'order:{order_id}'
            cached_order = redis_client.get(cache_key)

            if cached_order:
                logger.info(f"Cache HIT for order {order_id}")
                return jsonify(json.loads(cached_order)), 200
            else:
                logger.info(f"Cache MISS for order {order_id}")

        # Query database
        order = Order.query.get(order_id)

        if not order:
            return jsonify({'error': 'Order not found'}), 404

        # Cache for next time
        if redis_client:
            cache_key = f'order:{order_id}'
            redis_client.setex(cache_key, 300, json.dumps(order.to_dict()))

        return jsonify(order.to_dict()), 200

    except Exception as e:
        logger.error(f"Error retrieving order: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/orders', methods=['GET'])
def list_orders():
    """List all orders with pagination"""
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)

        orders = Order.query.order_by(Order.created_at.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )

        return jsonify({
            'orders': [order.to_dict() for order in orders.items],
            'total': orders.total,
            'page': page,
            'per_page': per_page,
            'pages': orders.pages
        }), 200

    except Exception as e:
        logger.error(f"Error listing orders: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/orders/<int:order_id>/status', methods=['PUT'])
def update_order_status(order_id):
    """Update order status"""
    try:
        data = request.get_json()

        if not data or 'status' not in data:
            return jsonify({'error': 'Status is required'}), 400

        order = Order.query.get(order_id)

        if not order:
            return jsonify({'error': 'Order not found'}), 404

        order.status = data['status']
        order.updated_at = datetime.utcnow()
        db.session.commit()

        logger.info(f"Order {order_id} status updated to {data['status']}")

        # Invalidate cache
        if redis_client:
            cache_key = f'order:{order_id}'
            redis_client.delete(cache_key)
            logger.info(f"Cache invalidated: {cache_key}")

        return jsonify(order.to_dict()), 200

    except Exception as e:
        logger.error(f"Error updating order: {e}")
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# Initialize database tables
with app.app_context():
    try:
        db.create_all()
        logger.info("Database tables created successfully")
    except Exception as e:
        logger.error(f"Error creating database tables: {e}")


if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
