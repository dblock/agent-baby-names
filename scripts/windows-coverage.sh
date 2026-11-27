#!/bin/bash
# Runs the Bats tests in Git Bash on Windows with Bash tracing, and fails unless they run every line that runs only
# there: the body of each `if [[ "$OSTYPE" == msys* ...` block in the plugin's scripts. kcov, which npm run coverage
# uses, cannot run on Windows. Needs Bash 4.1 or later and the npm development dependencies.
set -euo pipefail

cd "$(dirname "$0")/.."
root="$PWD"
# Started from npm, $PWD may be D:/a/..., but the scripts that the tests run see /d/a/....
command -v cygpath >/dev/null && root="$(cygpath -u "$root")"
scripts=(bin/agent-baby-names lib/* hosts/*/hook.sh strategies/*/strategy.sh)
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Every script of the plugin that a test runs reads this first, and writes each line it runs to the trace file.
cat >"$work/bash_env" <<'ENV'
case "$0" in
  "$COVERAGE_ROOT"/bin/* | "$COVERAGE_ROOT"/hosts/* | "$COVERAGE_ROOT"/strategies/*)
    exec 19>>"$COVERAGE_TRACE"
    BASH_XTRACEFD=19
    PS4='+${BASH_SOURCE[0]:-}:${LINENO}: '
    set -x
    ;;
esac
ENV
: >"$work/trace"
COVERAGE_ROOT="$root" COVERAGE_TRACE="$work/trace" BASH_ENV="$work/bash_env" node_modules/.bin/bats test

# The lines in Windows-only blocks, as file:line.
awk '
  FNR == 1 { inside = 0 }
  inside && /^fi$/ { inside = 0; next }
  inside && !/^[[:space:]]*(#|$)/ { print FILENAME ":" FNR }
  /^if \[\[ "\$OSTYPE" == msys\*/ { inside = 1 }
' "${scripts[@]}" | sort -u >"$work/expected"

# The lines that ran, as file:line relative to the repository.
sed -nE 's/^\++([^:]+):([0-9]+): .*/\1:\2/p' "$work/trace" | sed -E "s|^$root/||; s|^strategies/[^/]+/\.\./\.\./||" |
  sort -u >"$work/ran"

missed="$(comm -23 "$work/expected" "$work/ran")"
total="$(grep -c '' "$work/expected" || true)"
if [[ -n "$missed" ]]; then
  echo "The tests did not run these Windows-only lines:" >&2
  echo "$missed" >&2
  exit 1
fi
echo "The tests ran all $total Windows-only lines."
