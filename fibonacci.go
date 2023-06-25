package main

import (
	"math"
)

// fibonacci computes the n-th Fibonacci number
// according to Binet’s simplified formula
func fibonacci(n uint64) float64 {
	return math.Round(math.Pow(math.Phi, float64(n)) / math.Sqrt(5))
}
