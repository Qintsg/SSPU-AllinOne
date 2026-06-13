#!/usr/bin/env bash
# Lore 本地状态兼容脚本
# Project: SSPU-AllinOne
# File: status.sh
# Author: Qintsg
# Date: 2026-06-13 00:00

set -euo pipefail

range="${1:-HEAD~1..HEAD}"

if ! command -v lore >/dev/null 2>&1; then
  echo "未找到 lore 命令。请先运行 npm install -g lore-protocol。" >&2
  exit 1
fi

echo "== Git status =="
git status --short --branch

echo
echo "== Lore doctor =="
lore doctor

echo
echo "== Lore validate ($range) =="
lore validate "$range"
