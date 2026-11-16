#!/usr/bin/env bash
# One-command installer for photo-stack (Immich + iCloud backup) on a Mac.
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/LuisFGarcia23/photo-stack/main/install.sh)"
# Safe to re-run: updates the scripts but keeps your settings (.env) and database.
set -euo pipefail

REPO="LuisFGarcia23/photo-stack"
DIR="${PHOTO_STACK_DIR:-$HOME/photo-stack}"

say() { printf '\n==> %s\n' "$*"; }
die() { printf '\nError: %s\n' "$*" >&2; exit 1; }

[ "$(uname)" = Darwin ] || die "This installer is for macOS."

if [ ! -d /Applications/Docker.app ]; then
  say "Docker Desktop is needed first."
  echo "    Opening the download page. Install it, open it once, then run this command again."
  open "https://www.docker.com/products/docker-desktop/"
  exit 1
fi

say "Downloading photo-stack into $DIR ..."
mkdir -p "$DIR"
curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/main" | tar -xz -C "$DIR" --strip-components 1
chmod +x "$DIR/photo"

cd "$DIR"
# Read answers from the keyboard even if this script was piped in.
./photo setup </dev/tty

say "All set. Useful commands (run in Terminal from $DIR):"
echo "    ./photo watch     live download count"
echo "    ./photo status    what's running"
echo "    ./photo help      everything else"
echo
echo "    Tip: keep the Mac awake during the first download by running:  caffeinate -i"
