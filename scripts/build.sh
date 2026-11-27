#!/bin/bash
# Copies the files that the plugin runs from into build/, which a release zips and attaches to its GitHub Release.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
rm -rf build
mkdir build
git ls-files -z -- .claude-plugin .github/plugin assets bin docs hooks hosts lib strategies CHANGELOG.md LICENSE README.md |
  while IFS= read -r -d '' file; do
    mkdir -p "build/$(dirname "$file")"
    cp -p "$file" "build/$file"
  done
