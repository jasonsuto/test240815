#!/usr/bin/env bash
set -eu
# Installs committed AAR + sources (+ optional javadoc) into ~/.m2 for JitPack to pick up.
# https://docs.jitpack.io/building/
# File must use Unix LF line endings (see root .gitattributes). CRLF breaks bash on Linux/JitPack.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROP="$ROOT/delivery/jitpack/maven-coordinates.properties"

if [[ ! -f "$PROP" ]]; then
  echo "Missing $PROP"
  exit 1
fi

GROUP_ID=""
ARTIFACT_ID=""
VERSION=""

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line//$'\r'/}"
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// }" ]] && continue
  key="${line%%=*}"
  value="${line#*=}"
  key="${key// /}"
  case "$key" in
    groupId) GROUP_ID="$value" ;;
    artifactId) ARTIFACT_ID="$value" ;;
    version) VERSION="$value" ;;
  esac
done < "$PROP"

if [[ -z "$GROUP_ID" || -z "$ARTIFACT_ID" ]]; then
  echo "maven-coordinates.properties must set groupId and artifactId"
  exit 1
fi

# JitPack discovers artifacts under ~/.m2 using the same GAV as the dependency
# (tag / commit id as version, and com.github.USER.REPO for multi-module).
# Env JITPACK is documented at https://docs.jitpack.io/building/
if [[ "${JITPACK:-}" == "true" ]]; then
  cd "$ROOT"
  if git describe --tags --exact-match >/dev/null 2>&1; then
    VERSION=$(git describe --tags --exact-match)
  else
    VERSION=$(git describe --tags --always 2>/dev/null || true)
  fi
  if [[ -z "${VERSION:-}" ]]; then
    echo "JITPACK=true but could not determine version from git; set 'version=' in maven-coordinates.properties"
    exit 1
  fi
  echo "JitPack build: using Maven version '${VERSION}' from git"
fi

if [[ -z "${VERSION:-}" ]]; then
  echo "maven-coordinates.properties must set version (for non-JitPack local installs)"
  exit 1
fi

DIR="$ROOT/delivery/jitpack"
AAR="$DIR/${ARTIFACT_ID}.aar"
SRC="$DIR/${ARTIFACT_ID}-sources.jar"
DOC="$DIR/${ARTIFACT_ID}-javadoc.jar"

if [[ ! -f "$AAR" ]]; then
  echo "Missing required file: $AAR"
  exit 1
fi
if [[ ! -f "$SRC" ]]; then
  echo "Missing required file: $SRC"
  exit 1
fi

mvn -q install:install-file \
  -Dfile="$AAR" \
  -DgroupId="$GROUP_ID" \
  -DartifactId="$ARTIFACT_ID" \
  -Dversion="$VERSION" \
  -Dpackaging=aar \
  -DgeneratePom=true

mvn -q install:install-file \
  -Dfile="$SRC" \
  -DgroupId="$GROUP_ID" \
  -DartifactId="$ARTIFACT_ID" \
  -Dversion="$VERSION" \
  -Dpackaging=jar \
  -Dclassifier=sources

if [[ -f "$DOC" ]]; then
  mvn -q install:install-file \
    -Dfile="$DOC" \
    -DgroupId="$GROUP_ID" \
    -DartifactId="$ARTIFACT_ID" \
    -Dversion="$VERSION" \
    -Dpackaging=jar \
    -Dclassifier=javadoc
fi

extra=""
if [[ -f "$DOC" ]]; then
  extra=" + javadoc"
fi
echo "Installed ${GROUP_ID}:${ARTIFACT_ID}:${VERSION} (aar + sources${extra})"

