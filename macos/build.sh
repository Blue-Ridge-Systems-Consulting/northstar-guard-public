#!/bin/zsh
set -euo pipefail
mkdir -p bin
clang -fobjc-arc -O2 -Wall -Wextra -framework Foundation -framework Security \
  Sources/NorthstarGuard/main.m -o bin/northstar-guard
clang -fobjc-arc -O2 -Wall -Wextra -framework AppKit \
  Tools/dashboard_launcher.m -o bin/NorthstarGuardLauncher

install -d "$HOME/Library/Application Support/NorthstarGuard"
install -m 755 bin/northstar-guard "$HOME/Library/Application Support/NorthstarGuard/northstar-guard"
install -m 755 bin/NorthstarGuardLauncher "$HOME/Applications/Northstar Guard.app/Contents/MacOS/NorthstarGuardLauncher"
