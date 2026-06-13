# Git Flow 配置校验脚本
# Project: SSPU-AllinOne
# File: check_config.ps1
# Author: Qintsg
# Date: 2026-06-13 00:00

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Get-GitConfigValue {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    $value = git config --get $Name
    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    return $value
}

function Get-GitFlowCommandName {
    if (Get-Command gitflow -ErrorAction SilentlyContinue) {
        return "gitflow"
    }

    $gitFlowOutput = & git flow version 2>$null
    if ($LASTEXITCODE -eq 0) {
        return "git flow"
    }

    return $null
}

$gitFlowCommandName = Get-GitFlowCommandName
if ($null -eq $gitFlowCommandName) {
    Write-Error "未找到 Git Flow 命令。不同安装方式可能提供 gitflow 或 git flow；Windows 可尝试 winget install Kubis1982.GitFlow，macOS / Linux 请使用对应包管理器安装 git-flow。"
}

$expected = [ordered]@{
    "gitflow.branch.master" = "main"
    "gitflow.branch.develop" = "develop"
    "gitflow.prefix.feature" = "feature/"
    "gitflow.prefix.bugfix" = "bugfix/"
    "gitflow.prefix.release" = "release/"
    "gitflow.prefix.hotfix" = "hotfix/"
    "gitflow.prefix.support" = "support/"
    "gitflow.prefix.versiontag" = "v"
}

$failed = $false
foreach ($entry in $expected.GetEnumerator()) {
    $actual = Get-GitConfigValue -Name $entry.Key
    if ($actual -ne $entry.Value) {
        Write-Error "Git Flow 配置不匹配：$($entry.Key) 期望 '$($entry.Value)'，实际 '$actual'。"
        $failed = $true
    }
}

if ($failed) {
    exit 1
}

Write-Output "Git Flow 命令可用：$gitFlowCommandName"
Write-Output "Git Flow 配置符合 SSPU-AllinOne 规则。"
