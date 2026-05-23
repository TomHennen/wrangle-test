// Disposable test fixture for wrangle integration tests. The binary
// here exists purely so wrangle's Go build action has something to
// compile, package, and attest. The functions in this file have real
// behavior so the unit tests in main_test.go exercise something
// non-trivial — wrangle's go build action runs `go test -race ./...`
// before goreleaser, and a regression in this fixture would fail the
// integration run loudly.
package main

import (
	"errors"
	"fmt"
	"os"
	"strings"
)

func main() {
	fmt.Println(Hello())
	fmt.Println("sum(1, 2, 3) =", MustSum(1, 2, 3))
	slug, err := Slugify("  wrangle-test  Go  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "slugify failed: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("slug:", slug)
}

// Hello returns the fixture's name. Mirrors the python fixture's hello().
func Hello() string {
	return "wrangle-test-fixture-go"
}

// Sum returns the sum of values. Returns an error rather than
// panicking on overflow so tests can exercise the error path.
func Sum(values ...int) (int, error) {
	total := 0
	for _, v := range values {
		// Cheap overflow detection: an int + positive that goes
		// negative (or int + negative that goes positive) signals
		// wraparound. Two's-complement-specific but every Go
		// platform uses two's complement.
		next := total + v
		if (v > 0 && next < total) || (v < 0 && next > total) {
			return 0, errors.New("sum: integer overflow")
		}
		total = next
	}
	return total, nil
}

// MustSum is the panic-on-error variant. Used by main() to keep the
// binary's golden-path code path short.
func MustSum(values ...int) int {
	result, err := Sum(values...)
	if err != nil {
		panic(err)
	}
	return result
}

// Slugify returns text as a lowercase, single-hyphen-joined slug.
// Returns an error when text has no word characters — mirrors the
// python fixture's slugify().
func Slugify(text string) (string, error) {
	words := strings.Fields(strings.ToLower(text))
	if len(words) == 0 {
		return "", errors.New("slugify: requires non-empty text")
	}
	return strings.Join(words, "-"), nil
}
