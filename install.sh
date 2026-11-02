#!/bin/sh
# glmc installer: downloads the latest (or a given) release binary, verifies its
# SHA-256, and atomically replaces ~/.local/bin/glmc. Re-run to update.
#   curl -fsSL https://raw.githubusercontent.com/chunnylab/glmc/main/install.sh | sh
#   curl -fsSL .../install.sh | GLMC_VERSION=v3.17.1-1 sh
set -eu

REPO="chunnylab/glmc"
BIN_DIR="${GLMC_BIN_DIR:-$HOME/.local/bin}"
SHARE_DIR="${GLMC_SHARE_DIR:-$HOME/.local/share/glmc}"

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) ASSET="glmc-linux-x64" ;;
  *) echo "glmc: unsupported platform $(uname -s)-$(uname -m) (only Linux x64 is built)" >&2; exit 1 ;;
esac

if [ -n "${GLMC_VERSION:-}" ]; then
  BASE="https://github.com/$REPO/releases/download/$GLMC_VERSION"
else
  BASE="https://github.com/$REPO/releases/latest/download"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

echo "glmc: downloading $ASSET"
curl -fL --progress-bar -o "$TMP/$ASSET" "$BASE/$ASSET"
curl -fsSL -o "$TMP/SHA256SUMS" "$BASE/SHA256SUMS"
for f in LICENSE NOTICE.md THIRD-PARTY-NOTICES.md; do curl -fsSL -o "$TMP/$f" "$BASE/$f"; done

(cd "$TMP" && grep " $ASSET\$" SHA256SUMS | sha256sum -c -) >/dev/null \
  || { echo "glmc: checksum mismatch, nothing installed" >&2; exit 1; }

mkdir -p "$BIN_DIR" "$SHARE_DIR"
chmod 755 "$TMP/$ASSET"
# Same-filesystem rename is atomic: a running glmc keeps its old inode.
mv "$TMP/$ASSET" "$BIN_DIR/.glmc.new" && mv -f "$BIN_DIR/.glmc.new" "$BIN_DIR/glmc"
for f in LICENSE NOTICE.md THIRD-PARTY-NOTICES.md; do mv -f "$TMP/$f" "$SHARE_DIR/$f"; done

echo "glmc: installed $("$BIN_DIR/glmc" --version 2>/dev/null || echo '?') -> $BIN_DIR/glmc"
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) echo "glmc: add $BIN_DIR to PATH" ;; esac
