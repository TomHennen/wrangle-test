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
| `python/` | Python (`build_and_publish_python.yml`) | PEP 517 build, **pytest**, SBOM, SLSA L3 provenance, verify |
| `python-uv/` | Python (`build_and_publish_python.yml`) | uv build path, **pytest**, `verify-provenance: false` opt-out |
| `npm/` | npm (`build_and_publish_npm.yml`) | `npm ci` + **`npm test`** + `npm pack`, SBOM, SLSA L3 provenance, verify |
| `scan/` | Source scan (`check_source_change.yml`) | OSV + Zizmor on a minimal Go project |

Each fixture is a real, adopter-shaped project: the `shell`, `python`,
`python-uv`, and `npm` fixtures carry genuine unit tests, and wrangle's
build workflows run them (`bats`, `pytest`, `npm test`) before
packaging — a failing test fails the build. The `container` and `scan`
build types have no test-running step in wrangle, so those fixtures
carry no unit tests.

## Showcase workflow

`.github/workflows/showcase.yml` is a non-template, stable companion to
the per-PR integration test. It is **not** generated and **not** pinned
to a per-PR wrangle SHA — it lives on `main` and runs:

- **nightly** (and on demand via `workflow_dispatch`) — a heartbeat
  integration test of every wrangle reusable workflow against real
  GitHub Actions infrastructure, catching infrastructure regressions
  (Sigstore root rotation, registry API changes) between wrangle PRs;
- **on a `v*` tag push** — additionally attaches the SLSA L3 provenance,
  dist, and SBOM to the GitHub Release as permanent, clickable example
  artifacts for wrangle's adopter-facing docs.

It publishes the fixtures to TestPyPI, npmjs.org, and `ghcr.io`. See
[TomHennen/wrangle#200](https://github.com/TomHennen/wrangle/issues/200).

## Maintenance

Fixture dependencies are pinned and refreshed monthly via Dependabot.
Dependabot PRs are auto-merged when CI passes.
