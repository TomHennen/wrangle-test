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

Wrangle's CI dispatches this repo's `test-wrangle.yml` workflow on every
internal PR, passing the PR's head SHA. Each job invokes the
corresponding wrangle reusable workflow at that SHA, exercising the full
adopter-facing contract.

See [test/integration/SPEC.md](https://github.com/TomHennen/wrangle/blob/main/test/integration/SPEC.md)
in the wrangle repo for the full specification.

## Fixture layout

| Directory | Build type | What it exercises |
|-----------|-----------|-------------------|
| `shell/` | Shell (`build_shell.yml`) | shellcheck + bats on a minimal script |
| `container/` | Container (`build_and_publish_container.yml`) | Docker build, SBOM, Cosign sign, SLSA provenance |
| `scan/` | Source scan (`check_source_change.yml`) | OSV + Zizmor + Scorecard on a minimal Go project |

## Maintenance

Fixture dependencies are pinned and refreshed monthly via Dependabot.
Dependabot PRs are auto-merged when CI passes.
