# Lore 本地状态兼容脚本
# Project: SSPU-AllinOne
# File: status.ps1
# Author: Qintsg
# Date: 2026-06-13 00:00

[CmdletBinding()]
param(
    [string] $Range = "HEAD~1..HEAD"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command lore -ErrorAction SilentlyContinue)) {
    Write-Error "未找到 lore 命令。请先运行 npm install -g lore-protocol。"
}

Write-Output "== Git status =="
git status --short --branch

Write-Output ""
Write-Output "== Lore doctor =="
lore doctor

Write-Output ""
Write-Output "== Lore validate ($Range) =="
lore validate $Range
