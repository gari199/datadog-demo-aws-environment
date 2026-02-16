from flask import Flask, render_template, jsonify
import psycopg2
import os
from datetime import datetime

app = Flask(__name__)

# Database configuration
DB_HOST = os.getenv('DB_HOST', 'datadog-demo-postgres.c7ckk2qsyz0a.eu-central-1.rds.amazonaws.com')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME', 'ecommerce')
DB_USER = os.getenv('DB_USER', 'dbadmin')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'password')

def get_db_connection():
    """Create a database connection"""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

@app.route('/')
def index():
    """Admin dashboard page"""
    return render_template('index.html')

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'service': 'legacy-admin',
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/orders')
def get_orders():
    """Get all orders from database"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, user_id, product_name, quantity, price, total, status,
                   created_at, updated_at
            FROM orders
            ORDER BY created_at DESC
        """)

        orders = []
        for row in cursor.fetchall():
            orders.append({
                'id': row[0],
                'user_id': row[1],
                'product_name': row[2],
                'quantity': row[3],
                'price': float(row[4]),
                'total': float(row[5]),
                'status': row[6],
                'created_at': row[7].isoformat() if row[7] else None,
                'updated_at': row[8].isoformat() if row[8] else None
            })

        cursor.close()
        conn.close()

        return jsonify({
            'orders': orders,
            'total': len(orders)
        })

    except Exception as e:
        print(f"Error fetching orders: {e}")
        if conn:
            conn.close()
        return jsonify({'error': str(e)}), 500

@app.route('/api/stats')
def get_stats():
    """Get order statistics"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = conn.cursor()

        # Total orders
        cursor.execute("SELECT COUNT(*) FROM orders")
        total_orders = cursor.fetchone()[0]

        # Total revenue
        cursor.execute("SELECT COALESCE(SUM(total), 0) FROM orders")
        total_revenue = float(cursor.fetchone()[0])

        # Orders by status
        cursor.execute("""
            SELECT status, COUNT(*)
            FROM orders
            GROUP BY status
        """)
        orders_by_status = {row[0]: row[1] for row in cursor.fetchall()}

        # Recent orders count (last 24 hours)
        cursor.execute("""
            SELECT COUNT(*)
            FROM orders
            WHERE created_at > NOW() - INTERVAL '24 hours'
        """)
        recent_orders = cursor.fetchone()[0]

        cursor.close()
        conn.close()

        return jsonify({
            'total_orders': total_orders,
            'total_revenue': total_revenue,
            'orders_by_status': orders_by_status,
            'recent_orders_24h': recent_orders
        })

    except Exception as e:
        print(f"Error fetching stats: {e}")
        if conn:
            conn.close()
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5002))
    app.run(host='0.0.0.0', port=port, debug=False)
