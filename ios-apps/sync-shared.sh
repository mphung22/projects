#!/usr/bin/env bash
# Keeps every app package self-contained so each can be opened on its own
# in Swift Playgrounds or Xcode:
#   1. copies Shared/*.swift into every *.swiftpm/Shared/
#   2. copies each single-service app's form files (everything in App/ except
#      the @main file) into Seren.swiftpm/Services/<App>/ for the all-in-one app.
# Edit Shared/ or a single-service app's App/ folder, then run this script.
set -euo pipefail
cd "$(dirname "$0")"

for app in *.swiftpm; do
  rm -rf "$app/Shared"
  mkdir -p "$app/Shared"
  cp Shared/*.swift "$app/Shared/"
  echo "Synced Shared/ -> $app/Shared/"
done

rm -rf Seren.swiftpm/Services
for app in *.swiftpm; do
  name="${app%.swiftpm}"
  [ "$name" = "Seren" ] && continue
  mkdir -p "Seren.swiftpm/Services/$name"
  for file in "$app"/App/*.swift; do
    grep -q '^@main' "$file" && continue
    cp "$file" "Seren.swiftpm/Services/$name/"
  done
  echo "Copied $app/App forms -> Seren.swiftpm/Services/$name/"
done
