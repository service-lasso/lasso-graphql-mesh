#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
OS_NAME=$(uname -s)
case "$OS_NAME" in
  Linux*) PLATFORM="linux" ;;
  Darwin*) PLATFORM="darwin" ;;
  *) echo "Unsupported OS for package.sh: $OS_NAME" >&2; exit 1 ;;
esac
STAGING="$DIST/graphql-mesh-$PLATFORM"
TAR_PATH="$DIST/graphql-mesh-$PLATFORM.tar.gz"

mkdir -p "$DIST"
rm -rf "$STAGING"
mkdir -p "$STAGING"

cp -R "$ROOT/runtime" "$STAGING/runtime"
cp -R "$ROOT/config" "$STAGING/config"
cp "$ROOT/package.json" "$STAGING/runtime/package.json"
cp "$ROOT/package-lock.json" "$STAGING/runtime/package-lock.json"
npm ci --omit=dev --ignore-scripts --prefix "$STAGING/runtime"

rm -f "$TAR_PATH"
tar -czf "$TAR_PATH" -C "$STAGING" .
echo "Created $TAR_PATH"
