#!/bin/bash
set -e

APP_NAME="ClaudeBar"

swift build
codesign --force --sign "Apple Development: Vladimir Babin (8FNR8DGE9N)" ".build/debug/$APP_NAME"
".build/debug/$APP_NAME"
