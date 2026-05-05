#!/usr/bin/env bash
# shrink1999 uninstaller
set -euo pipefail

PLIST="$HOME/Library/LaunchAgents/com.shrink1999.autoshrink.plist"
BIN="$HOME/.local/bin/shrink1999"

bold() { printf "\033[1m%s\033[0m\n" "$*"; }
green(){ printf "\033[32m%s\033[0m\n" "$*"; }
dim()  { printf "\033[2m%s\033[0m\n" "$*"; }

bold "Uninstalling shrink1999..."

if [ -f "$PLIST" ]; then
  launchctl unload "$PLIST" 2>/dev/null || true
  rm -f "$PLIST"
  green "  ✓ Removed launchd agent"
fi

if [ -f "$BIN" ]; then
  rm -f "$BIN"
  green "  ✓ Removed $BIN"
fi

current="$(defaults read com.apple.screencapture location 2>/dev/null || echo "")"
if [ -n "$current" ] && [ "$current" != "$HOME/Desktop" ]; then
  echo
  echo "  Your macOS screenshot location is currently: $current"
  read -r -p "  Reset to ~/Desktop (default)? [y/N] " ans
  case "${ans:-N}" in
    y|Y|yes|YES)
      defaults delete com.apple.screencapture location 2>/dev/null || true
      killall SystemUIServer 2>/dev/null || true
      green "  ✓ Screenshots restored to ~/Desktop"
      ;;
  esac
fi

echo
dim "Kept (delete manually if you want):"
dim "  ~/ClaudeImages/         (your watched folder + any images in it)"
dim "  ~/.shrink1999-backups/  (originals before resizing)"
dim "  ~/Library/Logs/shrink1999*.log"
echo
bold "Done."
