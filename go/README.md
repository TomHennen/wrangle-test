# wrangle-test Go fixture

Disposable test fixture for wrangle's Go build pipeline integration tests. The binary in `cmd/example/main.go` exists solely so wrangle's `build_and_publish_go.yml` reusable workflow has something to:

1. Format-check (`gofmt -l .`)
2. Static-check (`go vet ./...`)
3. Test (`go test -race ./...`) — see [`cmd/example/main_test.go`](./cmd/example/main_test.go)
4. Vuln-scan (`govulncheck ./...`)
5. Build & package (goreleaser via `.goreleaser.yml`)
6. SBOM (syft)
7. Hash & SLSA provenance generation
8. Verify (slsa-verifier)

The fixture's functions (`Hello`, `Sum`, `Slugify`) have real behavior so the test suite exercises something non-trivial. A regression in any of them fails the integration run loudly, which is exactly the point: the integration test proves wrangle's Go build is actually wired up and executed against a real Go project.

This fixture is **not** consumed as a Go module by anyone — the module path (`github.com/tomhennen/wrangle-test/go`) exists only because Go's toolchain requires one for compilation.

## Why single-platform

`.goreleaser.yml` builds only `linux/amd64`. Multi-platform / multi-binary coverage is a separate fixture concern; this one prioritizes wrangle-pipeline coverage over matrix coverage. The release-vs-PR cache asymmetry, SLSA L3 generator hand-off, and verify-before-publish path are all exercised regardless of how many platforms the goreleaser config emits.
