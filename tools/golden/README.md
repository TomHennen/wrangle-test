# Release golden-set assertions

Regression net for the false-green class where wrangle's release-asset attach
silently no-ops (#501) or a scan attestation goes silently missing (#492).
After a release is assembled, the checks enumerate its assets and decode its
attestation bundles, then fail on any drift from a checked-in golden.

## Layers

- **Asset set** (`assets.golden`) — the rationalized release: each dist plus its
  paired `.intoto.jsonl`, one `<type>-metadata-<shortname>.zip` per build, and
  go's `checksums.txt`. Per-run-variable parts (package version → `<VER>`, go's
  embedded tag → `<TAG>`) are normalized, so the golden pins the *shape* and
  catches a missing metadata zip, an orphan bundle, or a reappearing flat SBOM.
- **Predicates** (`predicates.golden`) — the predicate-type multiset every
  bundle must carry: provenance + VSA + SBOM + one `scan/v1` per scan tool that
  ran, each keyed by tool name (`scan/v1[<tool>]`). Asserted per bundle, so a
  missing scan attestation — or a tool swapped for a duplicate of another —
  fails even when other bundles still carry it.

## Configs

The predicate golden is config-aware — the scan-tools set decides which
`scan/v1[<tool>]` lines appear. There is one golden dir per config:

- `showcase/` — the showcase's default scan tools (osv-scanner/zizmor/
  wrangle-lint). Checked in `showcase.yml`.
- `integration/` — the per-PR integration config (`scan-tools: zizmor`).
  Checked on the wrangle PR's `dispatch` via the temp-tag release path
  (`test-wrangle.yml.template`).

The asset set does not vary by config, so `integration/assets.golden` and
`showcase/assets.golden` are byte-identical by design.

## Run / update

```sh
# Assert (exit 1 on drift, with a diff + this command):
tools/golden/check_golden.sh assets     tools/golden/showcase <release-tag>
tools/golden/check_golden.sh predicates tools/golden/showcase <release-tag>

# Regenerate after an intended change (the leading `#` header is preserved):
tools/golden/check_golden.sh assets     tools/golden/showcase <release-tag> --update
```

`gh` reads the release, so `GH_TOKEN` / `GH_REPO` must be set as `gh` expects.
`tools/golden/test.bats` covers the normalization and drift logic hermetically.
