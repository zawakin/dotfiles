#!/bin/bash
# Open URL in Chrome "PR" profile.
# Falls back to default browser if Chrome or "PR" profile is not found.
#
# Usage: open-chrome-pr.sh <url>
# Set as: OPEN_URL_CMD="$HOME/dotfiles/scripts/open-chrome-pr.sh"
set -euo pipefail

URL="${1:?Usage: $0 <url>}"

if [[ "$(uname)" != "Darwin" ]]; then
  xdg-open "$URL" 2>/dev/null || echo "Open manually: $URL"
  exit 0
fi

LOCAL_STATE="$HOME/Library/Application Support/Google/Chrome/Local State"
if [[ ! -f "$LOCAL_STATE" ]]; then
  open "$URL"
  exit 0
fi

PROFILE_DIR=$(python3 -c "
import json, sys, pathlib
data = json.loads((pathlib.Path.home() / 'Library/Application Support/Google/Chrome/Local State').read_text())
profiles = data.get('profile', {}).get('info_cache', {})
for key, val in profiles.items():
    if val.get('name') == 'PR':
        print(key)
        sys.exit(0)
sys.exit(1)
" 2>/dev/null) || {
  open "$URL"
  exit 0
}

open -na "Google Chrome" --args --profile-directory="$PROFILE_DIR" "$URL"
