// Global state
let cart = [];
let products = [];
let apiGatewayUrl = '';

// Initialize app
async function init() {
  try {
    // Get API Gateway URL from server
    const configResponse = await fetch('/api/config');
    const config = await configResponse.json();
    apiGatewayUrl = config.apiGatewayUrl;

    // Load products
    await loadProducts();

    // Load cart from localStorage
    loadCartFromStorage();
    updateCartCount();
  } catch (error) {
    console.error('Initialization error:', error);
    showError('Failed to initialize application');
  }
}

// Load products from API
async function loadProducts() {
  const appDiv = document.getElementById('app');
  appDiv.innerHTML = '<div class="loading">Loading products...</div>';

  try {
    const response = await fetch(`${apiGatewayUrl}/api/products`);
    const data = await response.json();
    products = data.products;
    renderProducts();
  } catch (error) {
    console.error('Error loading products:', error);
    appDiv.innerHTML = '<div class="error">Failed to load products. Please try again later.</div>';
  }
}

// Render products
function renderProducts() {
  const appDiv = document.getElementById('app');

  if (products.length === 0) {
    appDiv.innerHTML = '<div class="loading">No products available</div>';
    return;
  }

  const productsHtml = products.map(product => `
    <div class="product-card">
      <div class="category">${product.category}</div>
      <h3>${product.name}</h3>
      <p>${product.description}</p>
      <div class="price">$${product.price.toFixed(2)}</div>
      <p>Stock: ${product.stock}</p>
      <button onclick="addToCart(${product.id})">Add to Cart</button>
    </div>
  `).join('');

  appDiv.innerHTML = `<div class="products-grid">${productsHtml}</div>`;
}

// Add to cart
function addToCart(productId) {
  const product = products.find(p => p.id === productId);
  if (!product) return;

  // Check if product already in cart
  const existingItem = cart.find(item => item.id === productId);

  if (existingItem) {
    existingItem.quantity += 1;
  } else {
    cart.push({
      id: product.id,
      name: product.name,
      price: product.price,
      quantity: 1
    });
  }

  saveCartToStorage();
  updateCartCount();
  showSuccess(`${product.name} added to cart!`);
}

// Remove from cart
function removeFromCart(productId) {
  cart = cart.filter(item => item.id !== productId);
  saveCartToStorage();
  updateCartCount();
  renderCart();
}

// Update cart count
function updateCartCount() {
  const count = cart.reduce((sum, item) => sum + item.quantity, 0);
  document.getElementById('cart-count').textContent = count;
}

// Open cart modal
function openCart() {
  document.getElementById('cart-modal').classList.add('active');
  renderCart();
}

// Close cart modal
function closeCart() {
  document.getElementById('cart-modal').classList.remove('active');
}

// Render cart
function renderCart() {
  const cartItemsDiv = document.getElementById('cart-items');

  if (cart.length === 0) {
    cartItemsDiv.innerHTML = '<div class="empty-cart">Your cart is empty</div>';
    document.getElementById('cart-total').textContent = '0.00';
    return;
  }

  const cartHtml = cart.map(item => `
    <div class="cart-item">
      <div>
        <strong>${item.name}</strong><br>
        $${item.price.toFixed(2)} x ${item.quantity}
      </div>
      <div>
        <div>$${(item.price * item.quantity).toFixed(2)}</div>
        <button class="remove-btn" onclick="removeFromCart(${item.id})">Remove</button>
      </div>
    </div>
  `).join('');

  cartItemsDiv.innerHTML = cartHtml;

  const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
  document.getElementById('cart-total').textContent = total.toFixed(2);
}

// Checkout
async function checkout() {
  if (cart.length === 0) {
    showError('Your cart is empty');
    return;
  }

  try {
    // Create orders for each cart item
    const orderPromises = cart.map(async item => {
      const orderData = {
        user_id: 1, // Mock user ID
        product_name: item.name,
        quantity: item.quantity,
        price: item.price
      };

      const orderResponse = await fetch(`${apiGatewayUrl}/api/orders`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(orderData)
      });

      if (!orderResponse.ok) {
        throw new Error('Failed to create order');
      }

      const order = await orderResponse.json();

      // Process payment for the order
      const paymentData = {
        order_id: order.id.toString(),
        amount: order.total,
        currency: 'USD',
        method: 'credit_card',
        card_number: '4532015112830366',
        card_expiry: '12/25',
        card_cvv: '123'
      };

      const paymentResponse = await fetch(`${apiGatewayUrl}/api/payments/process`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(paymentData)
      });

      if (!paymentResponse.ok) {
        throw new Error('Payment failed');
      }

      return await paymentResponse.json();
    });

    await Promise.all(orderPromises);

    // Clear cart
    cart = [];
    saveCartToStorage();
    updateCartCount();
    closeCart();

    showSuccess('Order placed successfully! Thank you for your purchase.');

  } catch (error) {
    console.error('Checkout error:', error);
    showError('Checkout failed. Please try again.');
  }
}

// Save cart to localStorage
function saveCartToStorage() {
  localStorage.setItem('cart', JSON.stringify(cart));
}

// Load cart from localStorage
function loadCartFromStorage() {
  const savedCart = localStorage.getItem('cart');
  if (savedCart) {
    cart = JSON.parse(savedCart);
  }
}

// Show success message
function showSuccess(message) {
  const appDiv = document.getElementById('app');
  const successDiv = document.createElement('div');
  successDiv.className = 'success';
  successDiv.textContent = message;
  appDiv.insertBefore(successDiv, appDiv.firstChild);

  setTimeout(() => {
    successDiv.remove();
  }, 3000);
}

// Show error message
function showError(message) {
  const appDiv = document.getElementById('app');
  const errorDiv = document.createElement('div');
  errorDiv.className = 'error';
  errorDiv.textContent = message;
  appDiv.insertBefore(errorDiv, appDiv.firstChild);

  setTimeout(() => {
    errorDiv.remove();
  }, 3000);
}

// Close modal when clicking outside
window.onclick = function(event) {
  const modal = document.getElementById('cart-modal');
  if (event.target === modal) {
    closeCart();
  }
}

// Initialize app when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
