#!/usr/bin/env bash
# shrink1999 installer
# Installs the watcher script + launchd agent. Optionally points macOS
# screenshots at the watched folder. Idempotent.

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/nicolaskasaks-ui/shrink1999/main"
BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/shrink1999"
WATCH_DIR="${SHRINK1999_DIR:-$HOME/ClaudeImages}"
PLIST="$HOME/Library/LaunchAgents/com.shrink1999.autoshrink.plist"
LABEL="com.shrink1999.autoshrink"

bold() { printf "\033[1m%s\033[0m\n" "$*"; }
dim()  { printf "\033[2m%s\033[0m\n" "$*"; }
green(){ printf "\033[32m%s\033[0m\n" "$*"; }

if [[ "$(uname)" != "Darwin" ]]; then
  echo "shrink1999 only supports macOS (uses sips, launchd, osascript)." >&2
  exit 1
fi

bold "Installing shrink1999..."
echo

# 1. Install the worker script
mkdir -p "$BIN_DIR"
if [ -f "./bin/shrink1999" ]; then
  cp "./bin/shrink1999" "$BIN"
else
  curl -fsSL "$REPO_RAW/bin/shrink1999" -o "$BIN"
fi
chmod +x "$BIN"
green "  ✓ Installed $BIN"

# 2. Make watched folder
mkdir -p "$WATCH_DIR"
green "  ✓ Watch folder: $WATCH_DIR"

# 3. Write launchd plist
mkdir -p "$(dirname "$PLIST")"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BIN</string>
    <string>$WATCH_DIR</string>
  </array>
  <key>WatchPaths</key>
  <array>
    <string>$WATCH_DIR</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>ThrottleInterval</key>
  <integer>2</integer>
  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/shrink1999.out.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/shrink1999.err.log</string>
</dict>
</plist>
EOF

launchctl unload "$PLIST" 2>/dev/null || true
launchctl load -w "$PLIST"
green "  ✓ launchd agent loaded ($LABEL)"

echo
bold "Optional: redirect macOS screenshots to $WATCH_DIR"
dim "  This way every Cmd+Shift+3/4/5 lands in the watched folder and gets"
dim "  shrunk + copied to clipboard automatically. You can skip this and"
dim "  just drag/drop images into $WATCH_DIR manually."
echo

current="$(defaults read com.apple.screencapture location 2>/dev/null || echo "$HOME/Desktop")"
echo "  Current screenshot location: $current"
echo
read -r -p "  Point screenshots to $WATCH_DIR? [y/N] " ans
case "${ans:-N}" in
  y|Y|yes|YES)
    defaults write com.apple.screencapture location "$WATCH_DIR"
    killall SystemUIServer 2>/dev/null || true
    green "  ✓ Screenshots now save to $WATCH_DIR"
    ;;
  *)
    dim "  Skipped. (Drop images into $WATCH_DIR yourself when you want them shrunk.)"
    ;;
esac

echo
bold "Done."
echo
echo "Try it:"
echo "  1. Drop a >1999px image into $WATCH_DIR (or take a screenshot)"
echo "  2. Wait ~1s for the notification"
echo "  3. Cmd+V into Claude (or anywhere)"
echo
echo "Logs:    ~/Library/Logs/shrink1999.log"
echo "Backups: ~/.shrink1999-backups/"
echo "Uninstall: curl -fsSL $REPO_RAW/uninstall.sh | bash"
