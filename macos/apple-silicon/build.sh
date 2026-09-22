#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}/.."
OUT="${0:A:h}/bin"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
mkdir -p "$OUT"

clang -arch arm64 -DNORTHSTAR_APPLE_SILICON=1 -isysroot "$SDK" -mmacosx-version-min=12.0 \
  -fobjc-arc -O2 -Wall -Wextra -framework Foundation -framework Security \
  "$ROOT/Sources/NorthstarGuard/main.m" -o "$OUT/northstar-guard"
clang -arch arm64 -isysroot "$SDK" -mmacosx-version-min=12.0 \
  -fobjc-arc -O2 -Wall -Wextra -framework AppKit \
  "$ROOT/Tools/dashboard_launcher.m" -o "$OUT/NorthstarGuardLauncher"

file "$OUT/northstar-guard" "$OUT/NorthstarGuardLauncher"
