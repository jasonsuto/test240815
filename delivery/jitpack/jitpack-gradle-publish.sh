#!/usr/bin/env bash
# JitPack install step: publish committed AAR/sources from delivery/jitpack/ via jitpack-upload.
# Uses repo root because Android detection can leave the shell cwd outside the root (./gradlew then fails with 127).
set -eu
ROOT="$(git rev-parse --show-toplevel)"
GW="$ROOT/gradlew"
if [ ! -f "$GW" ]; then
  echo "Missing ${GW} - commit gradlew and gradle/wrapper/ at the repository root." >&2
  exit 1
fi
chmod +x "$GW" 2>/dev/null || true
exec "$GW" -p "$ROOT/jitpack-upload" --no-daemon publishToMavenLocal
