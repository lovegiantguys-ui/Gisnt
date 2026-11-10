#!/usr/bin/env bash
set -euo pipefail
: "${CAPTURE_URL:?CAPTURE_URL is required}"
: "${CAPTURE_DIR:?CAPTURE_DIR is required}"
/usr/bin/time -p mkdir -p "$CAPTURE_DIR"
if ! command -v playwright-cli >/dev/null 2>&1; then
  echo 'Browser capture infrastructure unavailable: playwright-cli not found.' >&2
  exit 75
fi
session="capture-$$"
cleanup() { /usr/bin/time -p playwright-cli -s="$session" close >/dev/null 2>&1 || true; }
trap cleanup EXIT
if ! /usr/bin/time -p playwright-cli -s="$session" open "$CAPTURE_URL"; then
  echo 'Temporary browser/navigation failure.' >&2
  exit 75
fi
# Wait for the app's actual rendered content; a visible body alone is not sufficient.
/usr/bin/time -p playwright-cli -s="$session" eval "document.fonts.ready.then(()=>new Promise(r=>setTimeout(r,3500)))" || { echo 'Browser evaluation failed.' >&2; exit 75; }
if ! /usr/bin/time -p playwright-cli -s="$session" eval "() => { if(!document.querySelector('#scene canvas') || !document.querySelector('.panel h1')?.textContent.includes('bigger world')) throw new Error('Game did not render'); return true; }"; then
  echo 'Rendering defect: expected game canvas/content is missing.' >&2
  exit 1
fi
/usr/bin/time -p playwright-cli -s="$session" screenshot --filename="$CAPTURE_DIR/final-desktop.png" || { echo 'Desktop screenshot capture failed.' >&2; exit 75; }
/usr/bin/time -p playwright-cli -s="$session" resize 390 844
/usr/bin/time -p playwright-cli -s="$session" screenshot --filename="$CAPTURE_DIR/final-mobile.png" || { echo 'Mobile screenshot capture failed.' >&2; exit 75; }
