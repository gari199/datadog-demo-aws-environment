package handlers

import (
	"fmt"
	"log"
	"net/http"
	"payment-service/models"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

var (
	// In-memory storage for demo purposes
	payments = make(map[string]models.Payment)
	mu       sync.RWMutex
)

// ProcessPayment handles payment processing (mock implementation)
func ProcessPayment(c *gin.Context) {
	var req models.PaymentRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate payment method
	if req.Method != "credit_card" && req.Method != "debit_card" && req.Method != "paypal" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid payment method"})
		return
	}

	// Mock payment processing
	payment := models.Payment{
		ID:        uuid.New().String(),
		OrderID:   req.OrderID,
		Amount:    req.Amount,
		Currency:  req.Currency,
		Method:    req.Method,
		Status:    "pending",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	// Simulate payment processing
	success := mockPaymentGateway(req)

	if success {
		payment.Status = "completed"
		payment.TransactionID = fmt.Sprintf("TXN-%s", uuid.New().String()[:8])

		// Mask card number (last 4 digits only)
		if req.CardNumber != "" && len(req.CardNumber) >= 4 {
			payment.CardLast4 = req.CardNumber[len(req.CardNumber)-4:]
		}
	} else {
		payment.Status = "failed"
	}

	payment.UpdatedAt = time.Now()

	// Store payment
	mu.Lock()
	payments[payment.ID] = payment
	mu.Unlock()

	log.Printf("Payment processed: ID=%s, OrderID=%s, Status=%s, Amount=%.2f %s",
		payment.ID, payment.OrderID, payment.Status, payment.Amount, payment.Currency)

	c.JSON(http.StatusCreated, models.PaymentResponse{
		Payment: payment,
		Message: fmt.Sprintf("Payment %s", payment.Status),
	})
}

// GetPayment retrieves a payment by ID
func GetPayment(c *gin.Context) {
	paymentID := c.Param("id")

	mu.RLock()
	payment, exists := payments[paymentID]
	mu.RUnlock()

	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment not found"})
		return
	}

	c.JSON(http.StatusOK, payment)
}

// ListPayments returns all payments
func ListPayments(c *gin.Context) {
	mu.RLock()
	defer mu.RUnlock()

	paymentList := make([]models.Payment, 0, len(payments))
	for _, payment := range payments {
		paymentList = append(paymentList, payment)
	}

	c.JSON(http.StatusOK, gin.H{
		"payments": paymentList,
		"total":    len(paymentList),
	})
}

// GetPaymentsByOrder retrieves payments for a specific order
func GetPaymentsByOrder(c *gin.Context) {
	orderID := c.Param("order_id")

	mu.RLock()
	defer mu.RUnlock()

	orderPayments := make([]models.Payment, 0)
	for _, payment := range payments {
		if payment.OrderID == orderID {
			orderPayments = append(orderPayments, payment)
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"order_id": orderID,
		"payments": orderPayments,
		"total":    len(orderPayments),
	})
}

// mockPaymentGateway simulates a payment gateway
// Returns true for successful payment (90% success rate for demo)
func mockPaymentGateway(req models.PaymentRequest) bool {
	// Simulate processing delay
	time.Sleep(100 * time.Millisecond)

	// Intentional failures for testing
	if req.Amount > 10000 {
		log.Printf("Payment rejected: Amount too high (%.2f)", req.Amount)
		return false
	}

	if req.Method == "credit_card" && req.CardNumber == "4111111111111111" {
		log.Printf("Payment rejected: Test card number")
		return false
	}

	// 90% success rate
	return time.Now().UnixNano()%10 != 0
}

// HealthCheck returns service health status
func HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"service": "payment-service",
		"status":  "healthy",
	})
}
