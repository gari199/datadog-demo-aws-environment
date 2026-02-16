package models

import "time"

type Payment struct {
	ID            string    `json:"id"`
	OrderID       string    `json:"order_id"`
	Amount        float64   `json:"amount"`
	Currency      string    `json:"currency"`
	Method        string    `json:"method"` // credit_card, debit_card, paypal
	Status        string    `json:"status"` // pending, completed, failed
	CardLast4     string    `json:"card_last_4,omitempty"`
	TransactionID string    `json:"transaction_id,omitempty"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

type PaymentRequest struct {
	OrderID      string  `json:"order_id" binding:"required"`
	Amount       float64 `json:"amount" binding:"required,gt=0"`
	Currency     string  `json:"currency" binding:"required"`
	Method       string  `json:"method" binding:"required"`
	CardNumber   string  `json:"card_number,omitempty"`
	CardExpiry   string  `json:"card_expiry,omitempty"`
	CardCVV      string  `json:"card_cvv,omitempty"`
	PaypalEmail  string  `json:"paypal_email,omitempty"`
}

type PaymentResponse struct {
	Payment Payment `json:"payment"`
	Message string  `json:"message"`
}
