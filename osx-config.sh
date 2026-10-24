#!/bin/bash
#
# macOS settings, written as data so the same list can be applied or checked.
#
#   ./osx-config.sh         apply: write only the settings that differ, then
#                           restart Dock / Finder / SystemUIServer if needed
#   ./osx-config.sh check   report drift between this file and the machine,
#                           change nothing (make osx-check)
#
# The machine is the source of truth: when you change a setting in System
# Settings and want to keep it, run `make osx-check`, copy the "now" value
# into the list below and commit. Keep this file to settings that are plain
# `defaults` keys; things macOS does not expose as such (the number and order
# of Mission Control spaces, wallpaper per space, input sources) are not
# recorded here.
#
# Each SETTINGS entry is  host|domain|key|type|value  where host is empty or
# -currentHost, and type is one of bool, int, float, string.

set -u

MODE=${1:-apply}

SETTINGS=(
  ### Keyboard
  "|NSGlobalDomain|AppleKeyboardUIMode|int|3"                            # full keyboard access (tab through all controls)
  "|NSGlobalDomain|KeyRepeat|int|2"
  "|NSGlobalDomain|InitialKeyRepeat|int|12"
  "|NSGlobalDomain|ApplePressAndHoldEnabled|bool|false"                  # key repeat instead of the accent popup
  "|NSGlobalDomain|NSAutomaticPeriodSubstitutionEnabled|bool|false"
  "|NSGlobalDomain|NSAutomaticSpellingCorrectionEnabled|bool|false"

  ### Trackpad
  "|NSGlobalDomain|com.apple.mouse.tapBehavior|int|1"                    # tap to click
  "-currentHost|NSGlobalDomain|com.apple.mouse.tapBehavior|int|1"
  "|NSGlobalDomain|com.apple.trackpad.forceClick|bool|true"
  "|com.apple.driver.AppleBluetoothMultitouch.trackpad|Clicking|bool|true"
  "|com.apple.driver.AppleBluetoothMultitouch.trackpad|TrackpadThreeFingerTapGesture|int|2"

  ### Font smoothing (external displays)
  "|NSGlobalDomain|CGFontRenderingFontSmoothingDisabled|bool|false"
  "-currentHost|NSGlobalDomain|AppleFontSmoothing|int|1"

  ### General
  "|NSGlobalDomain|AppleShowAllExtensions|bool|true"
  "|NSGlobalDomain|com.apple.springing.enabled|bool|true"
  "|NSGlobalDomain|com.apple.springing.delay|float|0"
  "|NSGlobalDomain|NSWindowResizeTime|float|0.001"
  "|com.apple.CrashReporter|DialogType|string|none"
  "|com.apple.desktopservices|DSDontWriteNetworkStores|bool|true"      # no .DS_Store on network / USB volumes
  "|com.apple.desktopservices|DSDontWriteUSBStores|bool|true"
  "|com.apple.LaunchServices|LSQuarantine|bool|false"                    # no "downloaded from the internet" dialog

  ### Menu bar
  "|com.apple.menuextra.battery|ShowPercent|string|YES"
  "|com.apple.menuextra.clock|ShowSeconds|bool|true"
  "|com.apple.menuextra.clock|ShowDayOfWeek|bool|true"
  "|com.apple.menuextra.clock|ShowAMPM|bool|true"
  "|com.apple.menuextra.clock|ShowDate|bool|false"

  ### Dock
  "|com.apple.dock|orientation|string|right"
  "|com.apple.dock|autohide|bool|true"
  "|com.apple.dock|magnification|bool|true"
  "|com.apple.dock|largesize|int|71"

  ### Mission Control
  "|com.apple.dock|mru-spaces|bool|false"                                # keep spaces in the order I arranged them
  "|com.apple.dock|mcx-expose-disabled|bool|false"
  "|com.apple.dock|wvous-br-corner|int|14"                               # bottom-right hot corner: Quick Note

  ### Finder
  "|com.apple.finder|AppleShowAllFiles|string|YES"
  "|com.apple.finder|_FXShowPosixPathInTitle|bool|true"                  # full path in the title bar
  "|com.apple.finder|AnimateWindowZoom|bool|false"
  "|com.apple.finder|FXDefaultSearchScope|string|SCcf"                   # search the current folder
  "|com.apple.finder|FXEnableExtensionChangeWarning|bool|false"
  "|com.apple.finder|FXPreferredViewStyle|string|Nlsv"                   # list view
  "|com.apple.finder|QLEnableTextSelection|bool|true"
  "|com.apple.finder|ShowStatusBar|bool|true"
  "|com.apple.finder|ShowSidebar|bool|true"
  "|com.apple.finder|ShowExternalHardDrivesOnDesktop|bool|true"
  "|com.apple.finder|ShowRemovableMediaOnDesktop|bool|true"
  "|com.apple.finder|ShowHardDrivesOnDesktop|bool|false"
  "|com.apple.finder|WarnOnEmptyTrash|bool|false"
)

# Dock apps, left to right (persistent apps only; folders/recents untouched).
DOCK_APPS=(
  "/System/Library/CoreServices/Finder.app"
  "/Applications/Google Chrome.app"
  "/System/Applications/System Settings.app"
  "/Applications/iTerm.app"
  "/Applications/Slack.app"
  "/Applications/Obsidian.app"
  "/System/Applications/Utilities/Activity Monitor.app"
)

# Mission Control: control+1 .. control+8 switch to desktop 1 .. 8. These are
# off by default; macOS only offers them once the spaces exist, so creating the
# spaces themselves (and their order) stays a manual step after a fresh install.
# id|keycode  (hotkey ids 118-125 = "Switch to Desktop 1-8", 262144 = control)
SPACE_HOTKEYS=(
  "118|18" "119|19" "120|20" "121|21" "122|23" "123|22" "124|26" "125|28"
)
HOTKEYS_PLIST="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"

# ---------------------------------------------------------------------------

changed_domains=""
drift=0

note_change() { changed_domains="$changed_domains $1"; }

# Normalise a value to what `defaults read` prints for comparison.
expected_repr() {
  local type=$1 value=$2
  case "$type" in
    bool) case "$value" in true|TRUE|yes|YES|1) echo 1 ;; *) echo 0 ;; esac ;;
    float) awk -v v="$value" 'BEGIN { printf "%g", v }' ;;
    *) echo "$value" ;;
  esac
}

current_repr() {
  local host=$1 domain=$2 key=$3 type=$4 now
  # shellcheck disable=SC2086
  now=$(defaults $host read "$domain" "$key" 2>/dev/null) || { echo "(unset)"; return; }
  case "$type" in
    float) awk -v v="$now" 'BEGIN { printf "%g", v }' ;;
    *) echo "$now" ;;
  esac
}

sync_setting() {
  local host=$1 domain=$2 key=$3 type=$4 value=$5
  local want now
  want=$(expected_repr "$type" "$value")
  now=$(current_repr "$host" "$domain" "$key" "$type")
  [ "$now" = "$want" ] && return 0
  if [ "$MODE" = "check" ]; then
    printf '  %-46s %-40s want=%-8s now=%s\n' "$host $domain" "$key" "$want" "$now"
    drift=1
  else
    echo "  $domain $key: $now -> $want"
    # shellcheck disable=SC2086
    defaults $host write "$domain" "$key" "-$type" "$value"
    note_change "$domain"
  fi
}

sync_settings() {
  echo "defaults:"
  local entry host domain key type value
  for entry in "${SETTINGS[@]}"; do
    IFS='|' read -r host domain key type value <<< "$entry"
    sync_setting "$host" "$domain" "$key" "$type" "$value"
  done
}

sync_hidden_flags() {
  echo "hidden flags:"
  local path
  for path in "$HOME/Library" /Volumes; do
    if ls -lOd "$path" | awk '{print $5}' | grep -q hidden; then
      if [ "$MODE" = "check" ]; then
        echo "  $path is hidden (want visible)"; drift=1
      else
        echo "  unhiding $path"
        if [ -w "$path" ]; then chflags nohidden "$path"; else sudo chflags nohidden "$path"; fi
      fi
    fi
  done
}

sync_dock_apps() {
  echo "dock apps:"
  command -v dockutil >/dev/null 2>&1 || { echo "  dockutil not installed, skipping"; return; }
  local want now app
  want=$(for app in "${DOCK_APPS[@]}"; do basename "$app" .app; done)
  now=$(dockutil --list 2>/dev/null | awk -F'\t' '$3 == "persistentApps" { print $1 }')
  [ "$want" = "$now" ] && return 0
  if [ "$MODE" = "check" ]; then
    echo "  want: $(echo "$want" | tr '\n' ',' | sed 's/,$//; s/,/, /g')"
    echo "  now:  $(echo "$now" | tr '\n' ',' | sed 's/,$//; s/,/, /g')"
    drift=1
  else
    echo "  rebuilding"
    dockutil --remove all --no-restart >/dev/null
    for app in "${DOCK_APPS[@]}"; do
      [ -d "$app" ] || { echo "  missing, skipped: $app"; continue; }
      dockutil --add "$app" --no-restart >/dev/null
    done
    note_change com.apple.dock
  fi
}

sync_space_hotkeys() {
  echo "mission control hotkeys (control+1..8):"
  local entry id keycode enabled now_keycode
  for entry in "${SPACE_HOTKEYS[@]}"; do
    IFS='|' read -r id keycode <<< "$entry"
    enabled=$(plutil -extract "AppleSymbolicHotKeys.$id.enabled" raw "$HOTKEYS_PLIST" 2>/dev/null || echo false)
    now_keycode=$(plutil -extract "AppleSymbolicHotKeys.$id.value.parameters.1" raw "$HOTKEYS_PLIST" 2>/dev/null || echo "")
    [ "$enabled" = "true" ] && [ "$now_keycode" = "$keycode" ] && continue
    if [ "$MODE" = "check" ]; then
      echo "  hotkey $id: want enabled, keycode $keycode; now enabled=$enabled keycode=${now_keycode:-unset}"
      drift=1
    else
      echo "  enabling hotkey $id (control+keycode $keycode)"
      defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$id" \
        "{ enabled = 1; value = { parameters = (65535, $keycode, 262144); type = standard; }; }"
      note_change com.apple.symbolichotkeys
    fi
  done
}

restart_affected() {
  [ -z "$changed_domains" ] && { echo "nothing to change"; return; }
  echo "restarting:"
  case "$changed_domains" in *com.apple.dock*) echo "  Dock"; killall Dock ;; esac
  case "$changed_domains" in *com.apple.finder*) echo "  Finder"; killall Finder ;; esac
  case "$changed_domains" in *com.apple.menuextra*) echo "  SystemUIServer"; killall SystemUIServer ;; esac
  case "$changed_domains" in *com.apple.symbolichotkeys*)
    echo "  activating hotkeys"
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u ;;
  esac
  echo "some keyboard/trackpad settings take effect after logging out and back in"
}

case "$MODE" in
  apply|check) ;;
  *) echo "usage: $0 [apply|check]" >&2; exit 2 ;;
esac

sync_settings
sync_hidden_flags
sync_dock_apps
sync_space_hotkeys

if [ "$MODE" = "check" ]; then
  [ "$drift" -eq 0 ] && echo "no drift" || exit 1
else
  restart_affected
fi
