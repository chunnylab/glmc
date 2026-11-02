#!/usr/bin/env bash
# Build the glmc single-file binary from upstream ZCode source (Apache-2.0).
# Usage: ./build.sh [upstream-tag]   e.g. ./build.sh v3.17.1
set -euo pipefail
TAG="${1:-v3.17.1}"
NODE_VER=24.14.0      # pinned by upstream mise.toml
PNPM_VER=10.33.2
ROOT="$(cd "$(dirname "$0")" && pwd)"
WORK="$ROOT/.build"
mkdir -p "$WORK" "$ROOT/dist"

# Pinned Node toolchain, private to this build
NODE_DIR="$WORK/node-v$NODE_VER-linux-x64"
if [ ! -x "$NODE_DIR/bin/node" ]; then
  curl -fsSL "https://nodejs.org/dist/v$NODE_VER/node-v$NODE_VER-linux-x64.tar.xz" | tar -xJ -C "$WORK"
fi
export PATH="$NODE_DIR/bin:$PATH"
[ "$(pnpm -v 2>/dev/null || true)" = "$PNPM_VER" ] || npm i -g "pnpm@$PNPM_VER" >/dev/null
export COREPACK_ENABLE_PROJECT_SPEC=0

# Upstream source at the requested tag
SRC="$WORK/ZCode"
if [ ! -d "$SRC/.git" ]; then git clone -q https://github.com/zai-org/ZCode.git "$SRC"; fi
git -C "$SRC" fetch -q --tags origin
git -C "$SRC" checkout -q --force "refs/tags/$TAG"
git -C "$SRC" clean -qfdx -e node_modules

cd "$SRC"
pnpm install --frozen-lockfile
pnpm --filter '@zcode/cli...' build      # CLI plus every workspace package it depends on (upstream README)
pnpm exec turbo --skip-infer --cwd apps/zcode-cli run build --filter='!@zcode/cli'   # bundled plugins the SEA embeds
# Upstream gap: SEA packaging demands dist/index.js for every workspace dep of the TUI,
# but source-only packages (e.g. @zcode/shared) have no build step. The TUI bundle inlines
# them (esbuild), so an empty stub satisfies the check without changing runtime code.
for d in packages/*/ apps/zcode-cli/packages/*/ apps/zcode-cli/tools/*/; do
  [ -f "$d/package.json" ] && [ ! -f "$d/dist/index.js" ] && mkdir -p "$d/dist" && echo 'export {};' > "$d/dist/index.js" && echo "stub: $d"
done
cd apps/zcode-cli/packages/cli
node scripts/build-sea.mjs --target linux-x64


# Release assets: binary + upstream license/notice files (Apache-2.0 §4)
OUT="$ROOT/dist"; rm -rf "$OUT"; mkdir -p "$OUT"
cp dist/zcode-linux-x64 "$OUT/glmc-linux-x64"
cp "$SRC/LICENSE" "$OUT/LICENSE"; cp "$SRC/NOTICE.md" "$OUT/NOTICE.md"; cp dist/THIRD-PARTY-NOTICES.md "$OUT/THIRD-PARTY-NOTICES.md"
echo "$TAG" > "$OUT/UPSTREAM_TAG"
(cd "$OUT" && sha256sum glmc-linux-x64 > SHA256SUMS)
"$OUT/glmc-linux-x64" --version
