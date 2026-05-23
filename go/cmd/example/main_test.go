// Unit tests for the wrangle-test Go fixture. wrangle's Go build runs
// `go test -race ./...` before goreleaser, so a regression here fails
// the integration run loudly — proving the test step is actually wired
// up and executed (Tom's requirement: "tests should not be optional in
// wrangle-test").
package main

import (
	"strings"
	"testing"
)

func TestHello(t *testing.T) {
	if got := Hello(); got != "wrangle-test-fixture-go" {
		t.Fatalf("Hello() = %q, want %q", got, "wrangle-test-fixture-go")
	}
}

func TestSum_ZeroValues(t *testing.T) {
	got, err := Sum()
	if err != nil {
		t.Fatalf("Sum() returned unexpected error: %v", err)
	}
	if got != 0 {
		t.Fatalf("Sum() = %d, want 0", got)
	}
}

func TestSum_BasicValues(t *testing.T) {
	got, err := Sum(1, 2, 3)
	if err != nil {
		t.Fatalf("Sum(1, 2, 3) returned unexpected error: %v", err)
	}
	if got != 6 {
		t.Fatalf("Sum(1, 2, 3) = %d, want 6", got)
	}
}

func TestSum_Negatives(t *testing.T) {
	got, err := Sum(-4, 4)
	if err != nil {
		t.Fatalf("Sum(-4, 4) returned unexpected error: %v", err)
	}
	if got != 0 {
		t.Fatalf("Sum(-4, 4) = %d, want 0", got)
	}
}

func TestSum_OverflowReturnsError(t *testing.T) {
	const maxInt = int(^uint(0) >> 1)
	if _, err := Sum(maxInt, 1); err == nil {
		t.Fatal("Sum(maxInt, 1) returned no error; expected overflow")
	}
}

func TestSlugify_NormalizesCaseAndWhitespace(t *testing.T) {
	got, err := Slugify("Hello World")
	if err != nil {
		t.Fatalf("Slugify returned unexpected error: %v", err)
	}
	if got != "hello-world" {
		t.Fatalf("Slugify(\"Hello World\") = %q, want %q", got, "hello-world")
	}
}

func TestSlugify_CollapsesMultiSpace(t *testing.T) {
	got, err := Slugify("  Wrangle   Test  ")
	if err != nil {
		t.Fatalf("Slugify returned unexpected error: %v", err)
	}
	if got != "wrangle-test" {
		t.Fatalf("Slugify multi-space got %q, want %q", got, "wrangle-test")
	}
}

func TestSlugify_RejectsEmpty(t *testing.T) {
	_, err := Slugify("   ")
	if err == nil {
		t.Fatal("Slugify(blank) returned no error; expected ValueError-equivalent")
	}
	if !strings.Contains(err.Error(), "non-empty") {
		t.Fatalf("Slugify error %q does not mention 'non-empty'", err.Error())
	}
}
