#!/usr/bin/env bash
# Copies the shared Swift sources (Shared/) into each app package.
# Each .swiftpm must be self-contained so it can be opened on its own
# in Swift Playgrounds or Xcode — edit Shared/, then run this script.
set -euo pipefail
cd "$(dirname "$0")"
for app in *.swiftpm; do
  rm -rf "$app/Shared"
  mkdir -p "$app/Shared"
  cp Shared/*.swift "$app/Shared/"
  echo "Synced Shared/ -> $app/Shared/"
done
