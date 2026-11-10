#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"
PORT="${PORT:-3000}"
BUILD_DIR="$PROJECT_DIR/dist"
mkdir -p "$BUILD_DIR"
# Three.js add-ons import the bare specifier `three`; provide an import map in
# the built copy while keeping authored source untouched.
/usr/bin/time -p python3 - "$PROJECT_DIR/index.html" "$BUILD_DIR/index.html" <<'PY'
from pathlib import Path
import sys
source, output = map(Path, sys.argv[1:])
html = source.read_text()
marker = '<script type="module">'
mapping = '<script type="importmap">{"imports":{"three":"https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js","three/addons/":"https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/"}}</script>\n'
if marker not in html:
    raise SystemExit('Build error: expected module script not found in index.html')
html = html.replace(marker, mapping + marker, 1)
# Keep the game controls usable on narrow screens without changing authored source.
mobile = '''<style>@media(max-width:600px){.top{height:64px;padding:0 18px}.brand{font-size:18px;max-width:76px}.world{display:none}.topright{font-size:9px}.panel{left:14px;top:82px;bottom:12px;width:calc(100% - 28px);overflow-y:auto;padding-right:2px;scrollbar-width:thin}.intro h1{font-size:30px;margin:6px 0}.intro p{font-size:11px;line-height:1.45;max-width:330px}.eyebrow{font-size:9px}.card{margin-top:12px;padding:12px}.name{font-size:19px}.divider{margin:10px 0}.needs{margin-top:8px}.actions{margin-top:10px;padding-bottom:2px;gap:6px}.action{padding:10px 7px;font-size:10px;gap:6px}.action.primary{grid-column:span 2}.comp{display:none}.hint{display:none}}</style>'''
html = html.replace('</head>', mobile + '</head>', 1)
output.write_text(html)
PY
DEPLOY_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
/usr/bin/time -p mkdir -p "$DEPLOY_DIR"
/usr/bin/time -p python3 - "$PROJECT_DIR" "$BUILD_DIR" "$DEPLOY_DIR/deployment-output.json" <<'PY'
import json, pathlib, sys
project, directory, output = map(pathlib.Path, sys.argv[1:])
output.write_text(json.dumps({'project': str(project), 'directory': str(directory)}) + '\n')
PY
echo "Serving $BUILD_DIR on port $PORT"
/usr/bin/time -p python3 -m http.server "$PORT" --bind 0.0.0.0 --directory "$BUILD_DIR"
