// Package main is a minimal Go program for wrangle integration testing.
// It exists so check_source_change.yml has real dependencies to scan.
package main

import (
	"fmt"

	"golang.org/x/text/language"
)

func main() {
	fmt.Println(language.English)
}
