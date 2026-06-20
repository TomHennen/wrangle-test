#!/usr/bin/env bash
set -euo pipefail
set -f

# Golden-set assertions over a wrangle release: the assembled asset set and the
# predicate types inside each artifact's attestation bundle. Drift (a missing
# metadata zip, an orphan bundle, a reappearing flat SBOM, a silently-missing
# scan attestation) fails the check with a diff and the regenerate command.
#
# Usage:
#   check_golden.sh assets  <golden-dir> <release-tag> [--update]
#   check_golden.sh bundles <golden-dir> <release-tag> [--update]
#
# <golden-dir> holds assets.golden and bundles.golden for one config (the
# integration config and the showcase config each get their own dir). The
# release's assets are downloaded with `gh release`, so GH_TOKEN/GH_REPO must
# be set the way `gh` expects.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/golden/normalize.sh
source "${SCRIPT_DIR}/normalize.sh"

die() { printf 'ERROR: %s\n' "$1" >&2; exit 2; }

# Print the actual asset-name pattern set for a release on stdout.
actual_assets() {
    local tag="$1"
    gh release view "$tag" --json assets --jq '.assets[].name' \
        | normalize_assets "$tag"
}

# Print the predicate-type multiset carried by a single `.intoto.jsonl`: one
# "<count> <predicate-type>" line per distinct type. A per-tool scan
# attestation appears once per tool, so the multiset reflects the run's
# scan-tools config.
bundle_multiset() {
    local f="$1" types
    types="$(jq -er '(.dsseEnvelope.payload // .payload)|@base64d|fromjson|.predicateType' "$f")" \
        || die "malformed bundle: $(basename "$f")"
    printf '%s\n' "$types" | sort | uniq -c | sed -E 's/^ *//'
}

# Print the per-bundle predicate-type multiset on stdout. Asserting per bundle
# (not summed over the release) makes the check independent of how many
# bundles a stale/leftover asset adds, and pins the config for *every*
# artifact — so a scan attestation missing from one bundle fails even if
# another bundle still carries it. Every bundle must carry the same set;
# empty bundles (no DSSE lines) are reported so a no-op attach is caught.
actual_bundles() {
    local tag="$1" dir f ms first=""
    dir="$(mktemp -d)"
    gh release download "$tag" --dir "$dir" --pattern '*.intoto.jsonl' --clobber >/dev/null 2>&1 \
        || die "no .intoto.jsonl bundles in release $tag"
    set +f
    local bundles=("$dir"/*.intoto.jsonl)
    set -f
    [[ -e "${bundles[0]}" ]] || die "no .intoto.jsonl bundles downloaded for $tag"
    for f in "${bundles[@]}"; do
        ms="$(bundle_multiset "$f")"
        if [[ -z "$ms" ]]; then
            printf 'EMPTY BUNDLE: %s\n' "$(basename "$f")" >&2
            first="MISMATCH"
            continue
        fi
        if [[ -z "$first" ]]; then
            first="$ms"
        elif [[ "$ms" != "$first" ]]; then
            printf 'BUNDLE %s differs from the others:\n%s\n' "$(basename "$f")" "$ms" >&2
            first="MISMATCH"
        fi
    done
    [[ "$first" == "MISMATCH" ]] && die "bundles carry differing predicate-type sets (see above)"
    printf '%s\n' "$first"
}

# Compare actual against the golden file; on drift print a diff and the update
# command and exit 1. --update overwrites the golden and exits 0.
compare_or_update() {
    local actual="$1" golden_file="$2" update="$3" label="$4" update_cmd="$5"
    if [[ "$update" == "--update" ]]; then
        printf '%s\n' "$actual" > "$golden_file"
        printf 'Updated %s golden: %s\n' "$label" "$golden_file"
        return 0
    fi
    [[ -f "$golden_file" ]] || die "golden not found: $golden_file (run: $update_cmd)"
    if ! diff -u "$golden_file" <(printf '%s\n' "$actual") >/dev/null; then
        printf '%s golden drift (%s):\n' "$label" "$golden_file" >&2
        diff -u "$golden_file" <(printf '%s\n' "$actual") >&2 || true
        printf '\nIf this change is intended, regenerate the golden:\n  %s\n' "$update_cmd" >&2
        return 1
    fi
    printf '%s golden OK (%s)\n' "$label" "$golden_file"
}

main() {
    local mode="${1:?Usage: check_golden.sh <assets|bundles> <golden-dir> <release-tag> [--update]}"
    local golden_dir="${2:?missing <golden-dir>}"
    local tag="${3:?missing <release-tag>}"
    local update="${4:-}"
    case "$mode" in
        assets)
            compare_or_update "$(actual_assets "$tag")" \
                "${golden_dir}/assets.golden" "$update" "asset-set" \
                "tools/golden/check_golden.sh assets ${golden_dir} ${tag} --update"
            ;;
        bundles)
            compare_or_update "$(actual_bundles "$tag")" \
                "${golden_dir}/bundles.golden" "$update" "bundle-predicate" \
                "tools/golden/check_golden.sh bundles ${golden_dir} ${tag} --update"
            ;;
        *) die "unknown mode: $mode (expected assets or bundles)" ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
