const express = require('express');
const router = express.Router();

// Mock product data for demo purposes
const products = [
  {
    id: 1,
    name: 'Laptop Computer',
    description: 'High-performance laptop for professionals',
    price: 1299.99,
    category: 'Electronics',
    stock: 50,
    image_url: '/images/laptop.jpg'
  },
  {
    id: 2,
    name: 'Wireless Mouse',
    description: 'Ergonomic wireless mouse with precision tracking',
    price: 29.99,
    category: 'Electronics',
    stock: 200,
    image_url: '/images/mouse.jpg'
  },
  {
    id: 3,
    name: 'Mechanical Keyboard',
    description: 'RGB mechanical keyboard with premium switches',
    price: 149.99,
    category: 'Electronics',
    stock: 100,
    image_url: '/images/keyboard.jpg'
  },
  {
    id: 4,
    name: 'USB-C Hub',
    description: '7-in-1 USB-C hub with multiple ports',
    price: 49.99,
    category: 'Accessories',
    stock: 150,
    image_url: '/images/usb-hub.jpg'
  },
  {
    id: 5,
    name: 'Monitor 27"',
    description: '4K UHD monitor with HDR support',
    price: 449.99,
    category: 'Electronics',
    stock: 75,
    image_url: '/images/monitor.jpg'
  },
  {
    id: 6,
    name: 'Webcam HD',
    description: '1080p webcam with dual microphones',
    price: 79.99,
    category: 'Electronics',
    stock: 120,
    image_url: '/images/webcam.jpg'
  },
  {
    id: 7,
    name: 'Desk Lamp',
    description: 'LED desk lamp with adjustable brightness',
    price: 39.99,
    category: 'Office',
    stock: 180,
    image_url: '/images/lamp.jpg'
  },
  {
    id: 8,
    name: 'Headphones',
    description: 'Noise-cancelling wireless headphones',
    price: 249.99,
    category: 'Electronics',
    stock: 90,
    image_url: '/images/headphones.jpg'
  }
];

// Get all products
router.get('/', (req, res) => {
  console.log('Fetching all products');

  // Optional filtering by category
  const { category } = req.query;
  let filteredProducts = products;

  if (category) {
    filteredProducts = products.filter(p =>
      p.category.toLowerCase() === category.toLowerCase()
    );
  }

  res.json({
    products: filteredProducts,
    total: filteredProducts.length
  });
});

// Get product by ID
router.get('/:id', (req, res) => {
  const productId = parseInt(req.params.id);
  console.log(`Fetching product with ID: ${productId}`);

  const product = products.find(p => p.id === productId);

  if (!product) {
    return res.status(404).json({
      error: 'Product not found'
    });
  }

  res.json(product);
});

// Get product categories
router.get('/meta/categories', (req, res) => {
  const categories = [...new Set(products.map(p => p.category))];
  res.json({
    categories: categories
  });
});

module.exports = router;
