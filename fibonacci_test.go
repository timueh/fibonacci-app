package main

import (
	"testing"
)

func TestFibonacci(t *testing.T) {
	n, want := 10, 55
	got, err := fibonacci(n)

	if err != nil {
		t.Fatal("expected no error, got", err)
	}

	if want != got {
		t.Fatalf("got %v, want %v", got, want)
	}
}

func TestFibonacciForNonPositiveN(t *testing.T) {
	n, want := 0, 0
	got, err := fibonacci(n)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
	if want != got {
		t.Fatalf("got %v, want %v", got, want)
	}
}
