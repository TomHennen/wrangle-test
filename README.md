# wrangle-test

> **Do not depend on this repository.**
>
> This is a disposable integration-test surface for
> [TomHennen/wrangle](https://github.com/TomHennen/wrangle).
> Image tags under `ghcr.io/tomhennen/wrangle-test-staging` are rotated
> or deleted without notice. No external consumer may depend on this
> repository or its artifacts.

## What this is

A companion repo containing minimal fixture projects — one per wrangle
build type — used to integration-test wrangle's reusable workflows on
real GitHub Actions infrastructure.

Wrangle's CI pushes an ephemeral `integration/*` branch to this repo on
every internal PR, carrying a generated `test-wrangle.yml` with wrangle
pinned at the PR's head SHA. Each job invokes the corresponding wrangle
reusable workflow at that SHA, exercising the full adopter-facing contract.
Ephemeral branches are cleaned up by the dispatch script and a janitor
workflow (`cleanup-integration.yml`).

See [test/integration/SPEC.md](https://github.com/TomHennen/wrangle/blob/main/test/integration/SPEC.md)
in the wrangle repo for the full specification.

## Fixture layout

| Directory | Build type | What it exercises |
|-----------|-----------|-------------------|
| `shell/` | Shell (`build_shell.yml`) | shellcheck + **bats unit tests** on a minimal script |
| `container/` | Container (`build_and_publish_container.yml`) | Docker build, SBOM, SLSA provenance, cosign verify |
| `container-no-verify/` | Container (`build_and_publish_container.yml`) | Clone of `container/`, exercises `verify-image: false` |
| `python/` | Python (`build_and_publish_python.yml`) | PEP 517 build, **pytest**, SBOM, SLSA L3 provenance, verify |
| `python-uv/` | Python (`build_and_publish_python.yml`) | uv build path, **pytest**, `verify-provenance: false` opt-out |
| `npm/` | npm (`build_and_publish_npm.yml`) | `npm ci` + **`npm test`** + `npm pack`, SBOM, SLSA L3 provenance, verify |
| `pnpm/` | npm (`build_and_publish_npm.yml`) | pnpm tooling path: `pnpm install` + **`pnpm test`** + `pnpm pack` |
| `go/` | Go (`build_and_publish_go.yml`) | gofmt + vet + **`go test`** + govulncheck + goreleaser build, SBOM, SLSA L3 provenance, verify |
| `scan/` | Source scan (`check_source_change.yml`) | OSV + Zizmor on a minimal Go project |

Each fixture is a real, adopter-shaped project: the `shell`, `python`,
`python-uv`, `npm`, `pnpm`, and `go` fixtures carry genuine unit tests,
and wrangle's build workflows run them (`bats`, `pytest`, `npm test`,
`pnpm test`, `go test`) before packaging — a failing test fails the
build. The `container` and `scan` build types have no test-running step
in wrangle, so those fixtures carry no unit tests.

## Showcase workflow

`.github/workflows/showcase.yml` is a non-template, stable companion to
the per-PR integration test — not generated, not pinned to a per-PR
wrangle SHA. It runs on every `v*` tag push, exercising every wrangle
reusable workflow end to end (build, test, SBOM, SLSA L3 provenance,
verify, publish) and attaching the provenance + dist + SBOM to the
GitHub Release:

- **Tracking tags `vYYYYMMDD-<wrangle-sha7>`** — pushed automatically by
  wrangle's `release-showcase.yml` on every push to `main`. The
  push-tag script short-circuits when there's no `git diff` against
  the wrangle SHA embedded in the most recent tracking tag, so doc-only
  commits don't produce a run. A heartbeat that catches infrastructure
  regressions (Sigstore root rotation, registry API changes) between
  wrangle releases. Marked as pre-releases and **pruned after 30 days**
  by the showcase workflow itself (`prune-tracking-tags` job, filtered
  strictly on the tracking-tag regex AND `prerelease: true`, so curated
  releases are never touched).
- **Curated tags `vX.Y.Z`** — pushed by hand (or via GitHub's "Draft a
  new release" UI) for the stable, clickable example artifacts in
  wrangle's adopter-facing docs. Full releases, never pruned.

The showcase is driven by tag pushes rather than a `schedule:` trigger
on purpose: wrangle gates provenance-upload-to-Release on `refs/tags/*`,
so only a tag push exercises that path. Tracking tags are pushed from
wrangle with a PAT — a tag pushed by `GITHUB_TOKEN` would not trigger
`showcase.yml`. There is no `paths:` filter on the wrangle side;
the runtime-diff check in `push_showcase_tag.sh` replaces the
allowlist (which would silently drift). The workflow publishes the
fixtures to TestPyPI, npmjs.org, and `ghcr.io`. See
[TomHennen/wrangle#200](https://github.com/TomHennen/wrangle/issues/200).

## Maintenance

Fixture dependencies are pinned and refreshed monthly via Dependabot.
Dependabot PRs are auto-merged when CI passes.
