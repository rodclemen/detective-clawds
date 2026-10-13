#!/bin/zsh
# Compiles the comic-transition renderer into build/transitions (see Tools/Transitions/main.swift).
set -euo pipefail
cd "${0:A:h}/../.."
mkdir -p build
swiftc -O -swift-version 5 -target "$(uname -m)-apple-macos13.0" \
    Sources/App/{Pixel,Characters,Fights,Roster,Pose,Locations,Cast,Accents,Habits,ComicWipes}.swift \
    Sources/App/Art/*.swift Sources/App/Places/*.swift Sources/Shared/*.swift Tools/Transitions/main.swift -o build/transitions
echo "✓ build/transitions"
