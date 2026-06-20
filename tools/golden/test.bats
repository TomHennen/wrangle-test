#!/usr/bin/env bats

# Hermetic unit tests for the golden-set logic (normalization, per-bundle
# predicate extraction, drift comparison). The end-to-end assertion against a
# real release runs in showcase.yml / the integration template; this layer
# guards the pure logic without a network round-trip.
#
# Fixtures in testdata/ are hand-built minimal in-toto JSONL — a real bundle is
# ~80 KB of signatures that only obscures the one field under test
# (.predicateType), so a synthetic line is used deliberately.

setup() {
    DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    source "${DIR}/normalize.sh"
    source "${DIR}/check_golden.sh"
}

# --- normalize_assets ---

@test "normalize collapses package versions but keeps the dist/bundle pairing" {
    run normalize_assets v20260620-2245241 <<'EOF'
wrangle_test_fixture-0.0.1.dev27877558579-py3-none-any.whl
wrangle_test_fixture-0.0.1.dev27877558579-py3-none-any.whl.intoto.jsonl
EOF
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "wrangle_test_fixture-<VER>.whl" ]
    [ "${lines[1]}" = "wrangle_test_fixture-<VER>.whl.intoto.jsonl" ]
}

@test "normalize replaces the go archive tag (v-stripped) but keeps os/arch" {
    run normalize_assets v20260620-2245241 <<'EOF'
wrangle-test-fixture-go_20260620-2245241_linux_amd64.tar.gz
EOF
    [ "$status" -eq 0 ]
    [ "$output" = "wrangle-test-fixture-go_<TAG>_linux_amd64.tar.gz" ]
}

@test "normalize leaves the metadata zip and checksums untouched" {
    run normalize_assets v1.2.3 <<'EOF'
go-metadata-go.zip
checksums.txt
EOF
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "checksums.txt" ]
    [ "${lines[1]}" = "go-metadata-go.zip" ]
}

@test "normalize keeps a flat sbom distinct (it must never silently merge away)" {
    run normalize_assets v1.2.3 <<'EOF'
wrangle_test_fixture-0.0.1-sbom.spdx.json
wrangle_test_fixture-0.0.1.tar.gz
EOF
    [ "$status" -eq 0 ]
    printf '%s\n' "$output" | grep -q -- '-sbom.spdx.json'
}

# --- bundle_multiset ---

@test "bundle_multiset keys integration-config scan/v1 by tool name (zizmor)" {
    run bundle_multiset "${DIR}/testdata/bundle_integration.intoto.jsonl"
    [ "$status" -eq 0 ]
    [[ "$output" == *"1 https://github.com/TomHennen/wrangle/attestation/scan/v1[zizmor]"* ]]
    [[ "$output" == *"1 https://slsa.dev/provenance/v1"* ]]
    [[ "$output" == *"1 https://spdx.dev/Document"* ]]
}

@test "bundle_multiset keys showcase-config scan/v1 by tool name (3 distinct tools)" {
    run bundle_multiset "${DIR}/testdata/bundle_showcase.intoto.jsonl"
    [ "$status" -eq 0 ]
    [[ "$output" == *"1 https://github.com/TomHennen/wrangle/attestation/scan/v1[osv-scanner]"* ]]
    [[ "$output" == *"1 https://github.com/TomHennen/wrangle/attestation/scan/v1[wrangle-lint]"* ]]
    [[ "$output" == *"1 https://github.com/TomHennen/wrangle/attestation/scan/v1[zizmor]"* ]]
}

# The #492 false-green: a tool's attestation goes missing while a duplicate of
# another appears. The bare scan/v1 count stays 3, so the old count-only golden
# stayed green; tool-keying surfaces the swap (osv x2, no zizmor).
@test "bundle_multiset surfaces a missing scan tool masked by a duplicate (#492)" {
    run bundle_multiset "${DIR}/testdata/bundle_missing_tool.intoto.jsonl"
    [ "$status" -eq 0 ]
    [[ "$output" == *"2 https://github.com/TomHennen/wrangle/attestation/scan/v1[osv-scanner]"* ]]
    [[ "$output" != *"[zizmor]"* ]]
    run compare_or_update "$(bundle_multiset "${DIR}/testdata/bundle_missing_tool.intoto.jsonl")" \
        "${DIR}/showcase/predicates.golden" "" predicate "update-cmd"
    [ "$status" -eq 1 ]
}

@test "bundle_multiset reads the dsseEnvelope.payload fallback" {
    run bundle_multiset "${DIR}/testdata/bundle_dsse.intoto.jsonl"
    [ "$status" -eq 0 ]
    [ "$output" = "1 https://slsa.dev/provenance/v1" ]
}

# --- compare_or_update (drift detection) ---

@test "compare passes when actual matches the golden" {
    tmp="$(mktemp)"; printf 'a\nb\n' > "$tmp"
    run compare_or_update "$(printf 'a\nb')" "$tmp" "" label "update-cmd"
    [ "$status" -eq 0 ]
}

@test "compare fails on drift and prints the update command" {
    tmp="$(mktemp)"; printf 'a\nb\n' > "$tmp"
    run compare_or_update "$(printf 'a\nc')" "$tmp" "" label "the-update-cmd"
    [ "$status" -eq 1 ]
    [[ "$output" == *"the-update-cmd"* ]]
}

@test "compare with --update rewrites the golden" {
    tmp="$(mktemp)"; printf 'old\n' > "$tmp"
    run compare_or_update "$(printf 'new')" "$tmp" "--update" label "update-cmd"
    [ "$status" -eq 0 ]
    [ "$(cat "$tmp")" = "new" ]
}

@test "compare fails when the golden file is missing" {
    run compare_or_update "$(printf 'x')" "/nonexistent/path.golden" "" label "update-cmd"
    [ "$status" -eq 2 ]
}

# --- header-block explainer support ---

@test "compare ignores leading # header and blank lines on both sides" {
    tmp="$(mktemp)"; printf '# explainer line\n# another\n\na\nb\n' > "$tmp"
    run compare_or_update "$(printf '# different note\na\nb')" "$tmp" "" label "update-cmd"
    [ "$status" -eq 0 ]
}

@test "compare still drifts on a body change despite matching headers" {
    tmp="$(mktemp)"; printf '# h\na\nb\n' > "$tmp"
    run compare_or_update "$(printf '# h\na\nc')" "$tmp" "" label "the-update-cmd"
    [ "$status" -eq 1 ]
    [[ "$output" == *"the-update-cmd"* ]]
}

@test "--update preserves the leading header block and regenerates the body" {
    tmp="$(mktemp)"; printf '# keep me\n# line two\nold\n' > "$tmp"
    run compare_or_update "$(printf 'new1\nnew2')" "$tmp" "--update" label "update-cmd"
    [ "$status" -eq 0 ]
    [ "$(cat "$tmp")" = "$(printf '# keep me\n# line two\nnew1\nnew2')" ]
}

@test "the checked-in showcase predicates golden matches its fixture" {
    run compare_or_update "$(bundle_multiset "${DIR}/testdata/bundle_showcase.intoto.jsonl")" \
        "${DIR}/showcase/predicates.golden" "" predicate "update-cmd"
    [ "$status" -eq 0 ]
}

@test "the checked-in integration predicates golden matches its fixture" {
    run compare_or_update "$(bundle_multiset "${DIR}/testdata/bundle_integration.intoto.jsonl")" \
        "${DIR}/integration/predicates.golden" "" predicate "update-cmd"
    [ "$status" -eq 0 ]
}
