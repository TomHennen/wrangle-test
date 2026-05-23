module github.com/tomhennen/wrangle-test/go

// Bumped from `go 1.22` to clear ~15 OSV-Scanner findings against
// the Go stdlib that fire when the `go` directive points at an
// older minor release. OSV-Scanner reads this directive verbatim
// and flags any Go release <= the latest CVE's "fixed in" version,
// so the directive must be ahead of every known Go stdlib CVE's
// fix. As of 2026-05-23 the latest fix-in version is go1.25.10
// (multiple GO-2026-* CVEs). Bumping to 1.26 keeps headroom
// before the next batch of CVEs lands without forcing a bump on
// every Go patch release.
//
// setup-go resolves this to the latest 1.26.x release available
// on the runner. The Go modules ecosystem treats the `go`
// directive as a minimum — newer toolchains continue to work.
go 1.26
