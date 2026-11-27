#!/bin/bash
# Measures line coverage of the plugin's scripts by running the Bats tests under kcov, in kcov's Docker image,
# because kcov needs a newer Bash than macOS ships. Writes an HTML report and Cobertura XML to coverage/, and prints
# the coverage of each file. Needs Docker and the npm development dependencies; the tests need jq and Git.
set -euo pipefail

cd "$(dirname "$0")/.."
# kcov v43 has no image tag, so this pins the latest image by digest.
image="kcov/kcov@sha256:481289ae32e55e5b733019515acd10948a4f76dfed381765577db909664fc603"
rm -rf coverage
# The container runs as root, so it gives the report back to the user who ran this.
docker run --rm -v "$PWD:/src" -w /src -e OWNER="$(id -u):$(id -g)" "$image" sh -c '
  apt-get update -qq >/dev/null && apt-get install -y -qq git jq >/dev/null &&
  kcov --include-path=/src/bin,/src/lib,/src/hosts,/src/strategies /src/coverage node_modules/.bin/bats test
  status=$?; chown -R "$OWNER" /src/coverage; exit $status'

report="$(find coverage -path '*/bats.*/coverage.json' | head -1)"
[[ -n "$report" ]] || { echo "kcov wrote no coverage report." >&2; exit 1; }
cp "${report%/coverage.json}/cobertura.xml" coverage/cobertura.xml
jq -r '(.files | sort_by(.file)[] | "\(.percent_covered)% \(.file | sub("^/src/"; ""))"), "\(.percent_covered)% total"' \
  "$report"
