#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Bootstrapping Sora project from project.yml..."

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen not found."
  if command -v brew >/dev/null 2>&1; then
    echo "Installing xcodegen with Homebrew..."
    brew install xcodegen
  else
    echo "Homebrew is required to install xcodegen on macOS."
    exit 1
  fi
fi

xcodegen generate --spec "$ROOT_DIR/project.yml"

echo "Generated Sora.xcodeproj successfully."
