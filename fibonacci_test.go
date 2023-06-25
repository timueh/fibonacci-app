package main

import (
	"testing"
)

func TestFibonacci(t *testing.T) {
	n, want := uint64(10), 55.
	got := fibonacci(n)

	if want != got {
		t.Fatalf("got %v, want %v", got, want)
	}
}

func TestFibonacciForNonPositiveN(t *testing.T) {
	n, want := uint64(0), 0.
	got := fibonacci(n)
	if want != got {
		t.Fatalf("got %v, want %v", got, want)
	}
}
