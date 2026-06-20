#!/usr/bin/env bash
set -euo pipefail
set -f

# Normalize a release asset name to a golden pattern: collapse the
# per-run-variable parts (package version, go tag) to fixed placeholders so the
# golden matches the *shape* of the asset set, not a specific run. Extensions
# and the `.intoto.jsonl` bundle suffix are preserved, so the golden still
# distinguishes a dist from its paired bundle and from a metadata zip.
#
# Tokens normalized:
#   <VER>  a package version sitting before a dist extension — the npm/pnpm
#          `.tgz`, python `.whl` / `.tar.gz`, separated by `-` or `_`.
#   <TAG>  the release tag carried in go's archive name (vYYYYMMDD-<sha7>,
#          vX.Y.Z, or the per-PR pr-<n>-<runid>).
#
# Usage: normalize.sh <release-tag>   (asset names on stdin, one per line)

normalize_assets() {
    local tag="$1"
    local name
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        # Go embeds the tag (minus its `v` prefix) in its archive name,
        # bracketed by `_..._linux_<arch>`. Anchor the swap to that bracket so a
        # package version that happens to equal the tag (curated vX.Y.Z runs)
        # is not mistaken for the tag.
        name="$(printf '%s\n' "$name" | sed -E \
            "s/_${tag#v}(_linux_)/_<TAG>\1/")"
        # Replace the version that precedes a dist extension. The version run is
        # digit-led, of digits / letters / `.` / `_` / `-`; the trailing
        # extension (and any `.intoto.jsonl` bundle suffix) is preserved.
        name="$(printf '%s\n' "$name" | sed -E \
            's/[-_][0-9][0-9A-Za-z._-]*(\.(tgz|whl|tar\.gz))/-<VER>\1/')"
        printf '%s\n' "$name"
    done | sort -u
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    normalize_assets "${1:?Usage: normalize.sh <release-tag>}"
fi
