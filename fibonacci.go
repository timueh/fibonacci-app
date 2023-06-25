package main

import (
	"fmt"
	"math"
)

// fibonacci computes the n-th Fibonacci number
// according to Binet’s simplified formula
func fibonacci(n int) (int, error) {
	if n <= 0 {
		return 0, fmt.Errorf("n must be postive (is %v)", n)
	}
	f := math.Round(math.Pow(math.Phi, float64(n)) / math.Sqrt(5))

	return int(f), nil
}
