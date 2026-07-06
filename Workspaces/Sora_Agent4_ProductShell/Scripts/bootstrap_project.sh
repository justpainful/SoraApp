#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Sora bootstrap starting..."

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen not found."
  if command -v brew >/dev/null 2>&1; then
    echo "Installing xcodegen with Homebrew..."
    brew install xcodegen
  else
    echo "Homebrew not found. Install XcodeGen manually or ask the coding agent to create the Xcode project from project.yml."
    exit 1
  fi
fi

xcodegen generate

echo "Done. Open Sora.xcodeproj or run xcodebuild on a Mac."
