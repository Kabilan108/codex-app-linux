#!/usr/bin/env bash
set -euo pipefail

FLAKE="$(cd "$(dirname "$0")" && pwd)/flake.nix"
DMG_URL="https://persistent.oaistatic.com/codex-app-prod/Codex.dmg"

old_sri=$(sed -n '/codexDmg/,/hash =/{
  /hash =/{ s/.*"\(sha256-[^"]*\)".*/\1/p; q; }
}' "$FLAKE")

echo "Fetching latest Codex DMG (~150 MB)..."
tmp=$(mktemp)
trap "rm -f $tmp" EXIT

curl -fL --progress-bar -o "$tmp" "$DMG_URL"
new_sri=$(nix hash file --type sha256 --sri "$tmp")

if [ "$new_sri" = "$old_sri" ]; then
  echo "Already up to date ($old_sri)"
  exit 0
fi

echo "Updating DMG hash:"
echo "  old: $old_sri"
echo "  new: $new_sri"

sed -i "s|$old_sri|$new_sri|" "$FLAKE"

echo ""
echo "Now run: nix build ."
echo "If native module versions changed, update native-build/package.json and run:"
echo "  cd native-build && npm install --package-lock-only --ignore-scripts"
echo "  Then set npmDeps hash to lib.fakeHash, rebuild, and paste the correct hash."
