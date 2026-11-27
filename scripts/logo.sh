#!/bin/bash
# Prints the logo, a baby's head whose face is a "> _" prompt, as SVG. The committed assets/logo.svg is its output;
# regenerate it with scripts/logo.sh >assets/logo.svg. The colors switch for dark color schemes so the head stays
# visible on dark backgrounds.
set -euo pipefail

cat <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <title>Agent Baby Names</title>
  <style>
    .head { fill: #24292f; stroke: #24292f; }
    .face { fill: #7ee787; stroke: #7ee787; }
    @media (prefers-color-scheme: dark) {
      .head { fill: #d0d7de; stroke: #d0d7de; }
      .face { fill: #1a7f37; stroke: #1a7f37; }
    }
  </style>
  <g transform="translate(128,148)">
    <g class="head">
      <circle cx="-68" cy="10" r="15"/>
      <circle cx="68" cy="10" r="15"/>
      <circle cx="0" cy="0" r="68"/>
      <path d="M-4 -66 C-24 -78 -14 -104 6 -98 C22 -93 18 -74 2 -78" fill="none" stroke-width="10" stroke-linecap="round"/>
    </g>
    <g class="face">
      <path d="M-38 -16 l18 14 l-18 14" fill="none" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>
      <rect x="2" y="4" width="34" height="9" rx="2" stroke="none"/>
    </g>
  </g>
</svg>
SVG
