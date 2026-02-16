package main

import (
	"log"
	"os"
	"payment-service/handlers"

	"github.com/gin-gonic/gin"
)

func main() {
	// Set Gin mode
	mode := os.Getenv("GIN_MODE")
	if mode == "" {
		mode = "release"
	}
	gin.SetMode(mode)

	// Create Gin router
	r := gin.Default()

	// Middleware for logging
	r.Use(gin.Logger())
	r.Use(gin.Recovery())

	// Health check endpoint
	r.GET("/health", handlers.HealthCheck)

	// Payment endpoints
	r.POST("/process", handlers.ProcessPayment)
	r.GET("/payments/:id", handlers.GetPayment)
	r.GET("/payments", handlers.ListPayments)
	r.GET("/orders/:order_id/payments", handlers.GetPaymentsByOrder)

	// Get port from environment or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "5001"
	}

	log.Printf("Payment Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
