#!/bin/bash
# The default strategy: names a session after the repository it runs in, the last part of the checkout's origin, else
# upstream, remote URL, so ~/source/foo/master/lib and a fork checkout in ~/source/foo/dblock-foo are both "foo". A
# checkout without a remote is named after its folder, and outside a checkout the working folder names the session. It
# asks no model, keeps no cache, and has no options. A session in / or the home folder is left unnamed.
set -uo pipefail

cwd="$(jq -r '.cwd // empty')"
[[ -n "$cwd" && -d "$cwd" ]] || exit 0

top="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || top="$cwd"
url="$(git -C "$top" config --get-regexp '^remote\.(origin|upstream)\.url$' 2>/dev/null |
  awk '$1 == "remote.origin.url" { o = $2 } $1 == "remote.upstream.url" { u = $2 } END { print o ? o : u }')"
url="${url%/}"
url="${url%.git}"
name="${url##*[/:]}"
if [[ -z "$name" && "$top" != / && "$top" != "$HOME" ]]; then
  name="$(basename "$top")"
fi
echo "$name"
