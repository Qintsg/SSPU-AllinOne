#!/usr/bin/env bash
# Git Flow 配置校验脚本
# Project: SSPU-AllinOne
# File: check_config.sh
# Author: Qintsg
# Date: 2026-06-13 00:00

set -euo pipefail

git_flow_command=""
if command -v gitflow >/dev/null 2>&1; then
  git_flow_command="gitflow"
elif git flow version >/dev/null 2>&1; then
  git_flow_command="git flow"
else
  echo "未找到 Git Flow 命令。不同安装方式可能提供 gitflow 或 git flow；macOS 可使用 brew install git-flow，Linux 请使用发行版包管理器安装。" >&2
  exit 1
fi

check_config() {
  local key="$1"
  local expected="$2"
  local actual

  actual="$(git config --get "$key" || true)"
  if [[ "$actual" != "$expected" ]]; then
    echo "Git Flow 配置不匹配：$key 期望 '$expected'，实际 '$actual'。" >&2
    return 1
  fi
}

check_config "gitflow.branch.master" "main"
check_config "gitflow.branch.develop" "develop"
check_config "gitflow.prefix.feature" "feature/"
check_config "gitflow.prefix.bugfix" "bugfix/"
check_config "gitflow.prefix.release" "release/"
check_config "gitflow.prefix.hotfix" "hotfix/"
check_config "gitflow.prefix.support" "support/"
check_config "gitflow.prefix.versiontag" "v"

echo "Git Flow 命令可用：$git_flow_command"
echo "Git Flow 配置符合 SSPU-AllinOne 规则。"
